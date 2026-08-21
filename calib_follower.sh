#!/usr/bin/env bash
set -e

# 从 .env 读取机械臂端口配置(FOLLOWER_PORT / LEADER_PORT)
ENV_FILE="$(cd "$(dirname "$0")" && pwd)/.env"
[ -f "$ENV_FILE" ] || { echo "错误:找不到端口配置文件 $ENV_FILE" >&2; exit 1; }
source "$ENV_FILE"
[ -n "${FOLLOWER_PORT:-}" ] || { echo "错误:$ENV_FILE 中未设置 FOLLOWER_PORT" >&2; exit 1; }

lerobot-calibrate \
    --robot.type=so101_follower \
    --robot.port="$FOLLOWER_PORT" \
    --robot.id=xing_follower_arm
