#!/usr/bin/env bash
set -e

# pi0 微调:基于 pi0_base 权重,在 grab_cube 数据集上训练
# 注意:非 resume 模式下 output_dir 不能已存在,重跑前需先删除
export HF_ENDPOINT=https://hf-mirror.com

lerobot-train \
  --policy.type=pi0 \
  --policy.pretrained_path=lerobot/pi0_base \
  --dataset.repo_id=wux345/lerobot260823 \
  --dataset.streaming=false \
  --policy.empty_cameras=1 \
  --output_dir=/autodl-fs/data/lerobot/output_lerobot_train/grab_cube/pi0 \
  --job_name=grab_cube_pi0 \
  --policy.device=cuda \
  --policy.push_to_hub=false \
  --steps=20000 \
  --save_freq=5000 \
  --batch_size=4 \
  --policy.compile_model=false \
  --policy.gradient_checkpointing=true \
  --policy.dtype=bfloat16 \
  --policy.freeze_vision_encoder=false \
  --policy.train_expert_only=false \
  --swanlab.enable=true \
  --swanlab.project=Lerobot_GrabCube_pi0