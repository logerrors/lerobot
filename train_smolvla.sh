#!/usr/bin/env bash
set -e

# 基于 lerobot/smolvla_base 预训练权重微调(需配合 rename_map 使用)
# 数据集相机键 top/wrist 重命名为 checkpoint 期望的 camera1/camera2,
# 第三个 camera3 由 empty_cameras=1 自动补空图。
#
# 4080S 32GB 调优:batch 8→32 + bf16 提高 GPU 利用率(官方 recipe 在 A100 用 batch 64,
# 显存有余量可再试 64);num_workers=8 匹配 16 vCPU 的视频解码供给。

export dataset="wux345/lerobot260823"
export outputdir=""

HF_ENDPOINT=https://hf-mirror.com lerobot-train \
  --policy.path=lerobot/smolvla_base \
  --dataset.repo_id=${dataset} \
  --dataset.streaming=false \
  --rename_map='{"observation.images.top": "observation.images.camera1", "observation.images.wrist": "observation.images.camera2"}' \
  --policy.empty_cameras=1 \
  --output_dir=/home/xing/code/lerobot/output_lerobot_train/grab_cube/smolvla/ \
  --job_name=grab_cube_smolvla \
  --policy.device=cuda \
  --swanlab.enable=true \
  --swanlab.project=Lerobot_GrabCube_smolvla \
  --policy.push_to_hub=false \
  --steps=20000 \
  --save_freq=5000 \
  --batch_size=32 \
  --num_workers=8 \
  --accelerator.mixed_precision=bf16