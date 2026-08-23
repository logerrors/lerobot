#!/usr/bin/env bash
set -e

# 从 .env 读取机械臂端口配置(FOLLOWER_PORT)
ENV_FILE="$(cd "$(dirname "$0")" && pwd)/.env"
[ -f "$ENV_FILE" ] || { echo "错误:找不到端口配置文件 $ENV_FILE" >&2; exit 1; }
source "$ENV_FILE"
[ -n "${FOLLOWER_PORT:-}" ] || { echo "错误:$ENV_FILE 中未设置 FOLLOWER_PORT" >&2; exit 1; }

# 训练产出的最新 checkpoint(push_to_hub=false,所以用本地路径)
POLICY_PATH=/home/xing/bypy/pretrained_model

lerobot-rollout \
    --strategy.type=base \
    --policy.path="$POLICY_PATH" \
    --robot.type=so101_follower \
    --robot.port="$FOLLOWER_PORT" \
    --robot.id=xing_follower_arm \
    --robot.cameras='{ top: {type: opencv, index_or_path: 0, width: 640, height: 480, fps: 30, fourcc: "MJPG", rotation: 180}, wrist: {type: opencv, index_or_path: 2, width: 640, height: 480, fps: 30, fourcc: "MJPG"} }' \
    --task="Grab the cube" \
    --duration=50 \
    --display_data=true
