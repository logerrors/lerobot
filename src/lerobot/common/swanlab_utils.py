#!/usr/bin/env python

# Copyright 2024 The HuggingFace Inc. team. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
import logging
import os
import re
from glob import glob
from pathlib import Path

import torch
from huggingface_hub.constants import SAFETENSORS_SINGLE_FILE
from termcolor import colored

from lerobot.common.wandb_utils import cfg_to_group
from lerobot.configs.train import TrainPipelineConfig
from lerobot.utils.constants import PRETRAINED_MODEL_DIR


def get_swanlab_run_id_from_filesystem(log_dir: Path) -> str | None:
    """Best-effort recovery of the previous SwanLab run id from the local log directory.

    SwanLab stores each run under `{log_dir}/run-<yyyymmdd_hhmmss>-<id>`. Returns None
    when no previous run can be found.
    """
    paths = glob(str(log_dir / "run-*"))
    paths = [p for p in paths if os.path.isdir(p)]
    if not paths:
        return None
    latest = max(paths, key=os.path.getmtime)
    match = re.search(r"run-\d{8}_\d{6}-(.+)$", os.path.basename(latest))
    if match is None:
        return None
    return match.group(1)


class SwanLabLogger:
    """A helper class to log objects using SwanLab (https://swanlab.cn).

    It mirrors the `WandBLogger` interface so it can be used as a drop-in replacement
    in the training loop.
    """

    def __init__(self, cfg: TrainPipelineConfig):
        self.cfg = cfg.swanlab
        self.log_dir = cfg.output_dir
        self.job_name = cfg.job_name
        self.env_fps = cfg.env.fps if cfg.env else None
        self._group = cfg_to_group(cfg)

        import swanlab

        run_id = (
            self.cfg.run_id
            if self.cfg.run_id
            else get_swanlab_run_id_from_filesystem(self.log_dir)
            if cfg.resume
            else None
        )

        # SwanLab accepts 'online', 'offline', 'local' and 'disabled'.
        mode = self.cfg.mode if self.cfg.mode in ["online", "offline", "local", "disabled"] else "online"

        swanlab.init(
            id=run_id,
            project=self.cfg.project,
            workspace=self.cfg.entity,
            name=self.job_name,
            description=self.cfg.notes,
            tags=cfg_to_group(cfg, return_list=True),
            log_dir=str(self.log_dir),
            config=cfg.to_dict(),
            job_type="train_eval",
            resume="must" if cfg.resume else None,
            mode=mode,
        )
        run = swanlab.get_run()
        run_id = run.id
        # NOTE: We override cfg.swanlab.run_id with the swanlab run id so that resuming
        # a training run can reconnect to the same experiment.
        cfg.swanlab.run_id = run_id
        logging.info(colored("Logs will be synced with SwanLab.", "blue", attrs=["bold"]))
        try:
            url = run.url
            if url:
                logging.info(f"Track this run --> {colored(url, 'yellow', attrs=['bold'])}")
        except Exception:
            pass
        self._swanlab = swanlab

    def log_policy(self, checkpoint_dir: Path):
        """Uploads the policy checkpoint files to the SwanLab run."""
        if self.cfg.disable_artifact:
            return

        pretrained_model_dir = checkpoint_dir / PRETRAINED_MODEL_DIR
        adapter_model_file = pretrained_model_dir / "adapter_model.safetensors"
        standard_model_file = pretrained_model_dir / SAFETENSORS_SINGLE_FILE

        files_to_upload: list[Path] = []
        if adapter_model_file.exists():
            # PEFT model: upload adapter files and configs
            files_to_upload.append(adapter_model_file)
            for extra in ("adapter_config.json", "config.json"):
                extra_file = pretrained_model_dir / extra
                if extra_file.exists():
                    files_to_upload.append(extra_file)
        elif standard_model_file.exists():
            # Standard model: upload the single safetensors file
            files_to_upload.append(standard_model_file)
        else:
            logging.warning(
                f"No {SAFETENSORS_SINGLE_FILE} or adapter_model.safetensors found in {pretrained_model_dir}. "
                "Skipping model file upload to SwanLab."
            )
            return

        run = self._swanlab.get_run()
        for file in files_to_upload:
            run.save(str(file), policy="now")

    def log_dict(self, d: dict, step: int | None = None, mode: str = "train", custom_step_key: str | None = None):
        if mode not in {"train", "eval"}:
            raise ValueError(mode)
        if step is None and custom_step_key is None:
            raise ValueError("Either step or custom_step_key must be provided.")

        # When a custom step key is provided (e.g. for asynchronous RL training where
        # interaction steps and optimization steps differ), its value is used as the
        # logging step for the metrics.
        log_step = step if custom_step_key is None else d[custom_step_key]

        for k, v in d.items():
            # Policies may put auxiliary per-sample tensors (e.g. SmolVLA's
            # `losses_after_forward`) in the log dict; silently skip them.
            if isinstance(v, torch.Tensor):
                continue
            if not isinstance(v, (int, float, str)):
                logging.warning(
                    f'SwanLab logging of key "{k}" was ignored as its type "{type(v)}" is not handled by this wrapper.'
                )
                continue

            # Do not log the custom step key itself.
            if custom_step_key is not None and k == custom_step_key:
                continue

            self._swanlab.log(data={f"{mode}/{k}": v}, step=log_step)

    def log_video(self, video_path: str, step: int, mode: str = "train"):
        if mode not in {"train", "eval"}:
            raise ValueError(mode)

        swanlab_video = self._swanlab.Video(video_path)
        self._swanlab.log({f"{mode}/video": swanlab_video}, step=step)
