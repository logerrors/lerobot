#!/usr/bin/env bash
set -e

lerobot-train \
  --dataset.repo_id=wux345/lerobot260821-night \
  --dataset.streaming=false \
  --policy.type=act \
  --output_dir=/home/xing/code/lerobot/output_lerobot_train/grab_cube/act/ \
  --job_name=grab_cube_act \
  --policy.device=cuda \
  --swanlab.enable=true \
  --swanlab.project=Lerobot_GrabCube \
  --policy.push_to_hub=false \
  --steps=20000 \
  --batch_size=8
