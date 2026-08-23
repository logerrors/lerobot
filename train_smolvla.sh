#!/usr/bin/env bash
set -e

# 基于 lerobot/smolvla_base 预训练权重微调(需配合 rename_map 使用)
# 数据集相机键 top/wrist 重命名为 checkpoint 期望的 camera1/camera2,
# 第三个 camera3 由 empty_cameras=1 自动补空图。

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
  --batch_size=8