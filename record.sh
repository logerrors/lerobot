#!/usr/bin/env bash
set -e

# 从 .env 读取机械臂端口配置(FOLLOWER_PORT / LEADER_PORT)
ENV_FILE="$(cd "$(dirname "$0")" && pwd)/.env"
[ -f "$ENV_FILE" ] || { echo "错误:找不到端口配置文件 $ENV_FILE" >&2; exit 1; }
source "$ENV_FILE"
[ -n "${FOLLOWER_PORT:-}" ] || { echo "错误:$ENV_FILE 中未设置 FOLLOWER_PORT" >&2; exit 1; }
[ -n "${LEADER_PORT:-}" ] || { echo "错误:$ENV_FILE 中未设置 LEADER_PORT" >&2; exit 1; }

lerobot-record \
    --robot.type=so101_follower \
    --robot.port="$FOLLOWER_PORT" \
    --robot.id=xing_follower_arm \
    --robot.cameras='{ top: {type: opencv, index_or_path: 0, width: 640, height: 480, fps: 30, fourcc: "MJPG", rotation: 180}, wrist: {type: opencv, index_or_path: 2, width: 640, height: 480, fps: 30, fourcc: "MJPG"} }' \
    --teleop.type=so101_leader \
    --teleop.port="$LEADER_PORT" \
    --teleop.id=xing_leader_arm \
    --display_data=true \
    --dataset.repo_id=wux345/lerobot260821-night \
    --dataset.num_episodes=40 \
    --dataset.single_task="Grab the cube" \
    --dataset.push_to_hub=false \
    --dataset.episode_time_s=15 \
    --dataset.reset_time_s=6
