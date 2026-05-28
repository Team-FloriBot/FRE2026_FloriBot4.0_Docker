#!/bin/bash
set -eo pipefail

source /opt/ros/jazzy/setup.bash
source /ws/install/setup.bash

RSLIDAR_CONFIG="${RSLIDAR_CONFIG:-/ws/config/rslidar_config.yaml}"
GROUND_SEGMENTATION_CONFIG="${GROUND_SEGMENTATION_CONFIG:-/ws/config/ground_segmentation.yaml}"
GROUND_SEGMENTATION_ENABLE="${GROUND_SEGMENTATION_ENABLE:-true}"

pids=()

shutdown()
{
  echo "[robosense] Stopping RoboSense processes..."
  kill "${pids[@]}" 2>/dev/null || true
  wait 2>/dev/null || true
  exit 0
}

trap shutdown SIGINT SIGTERM

echo "[robosense] Starting RoboSense AIRY driver"
echo "[robosense] LiDAR config: ${RSLIDAR_CONFIG}"

ros2 run rslidar_sdk rslidar_sdk_node \
  --ros-args \
  -p config_path:="${RSLIDAR_CONFIG}" &

pids+=($!)

sleep 2

if [ "${GROUND_SEGMENTATION_ENABLE}" = "true" ] || \
   [ "${GROUND_SEGMENTATION_ENABLE}" = "1" ]; then

  echo "[robosense] Starting ground segmentation"
  echo "[robosense] Segmentation config: ${GROUND_SEGMENTATION_CONFIG}"

  ros2 run ground_segmentation ground_segmentation_node \
    --ros-args \
    --params-file "${GROUND_SEGMENTATION_CONFIG}" &

  pids+=($!)
else
  echo "[robosense] Ground segmentation disabled"
fi

echo "[robosense] Started ${#pids[@]} RoboSense process(es)"
echo "[robosense] Container will stay alive until stopped"

set +e
wait
