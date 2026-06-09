#!/bin/bash
set -eo pipefail

source /opt/ros/jazzy/setup.bash
source /ws/install/setup.bash

RSLIDAR_CONFIG="${RSLIDAR_CONFIG:-/ws/install/rslidar_sdk/share/rslidar_sdk/config/config.yaml}"
GROUND_SEGMENTATION_ENABLE="${GROUND_SEGMENTATION_ENABLE:-true}"
GROUND_SEGMENTATION_LAUNCH="${GROUND_SEGMENTATION_LAUNCH:-ground_segmentation_headless.launch.py}"
POINTCLOUD_TO_LASERSCAN_LAUNCH="${POINTCLOUD_TO_LASERSCAN_LAUNCH:-pointcloud_to_laserscan_launch.py}"

# Robosense must not contribute transforms to the robot-wide TF tree.
# The headless launch file applies the same /tf and /tf_static remappings.

PIDS=()

shutdown() {
  echo "[start_robosense] Shutting down child processes..."
  for pid in "${PIDS[@]}"; do
    if kill -0 "${pid}" 2>/dev/null; then
      kill "${pid}" 2>/dev/null || true
    fi
  done
  wait || true
}

trap shutdown EXIT INT TERM

if [ "${GROUND_SEGMENTATION_ENABLE}" = "true" ] || \
   [ "${GROUND_SEGMENTATION_ENABLE}" = "1" ]; then

  echo "[start_robosense] Starting RoboSense + ground segmentation via launch file: ${GROUND_SEGMENTATION_LAUNCH}"
  echo "[start_robosense] RSLIDAR_CONFIG=${RSLIDAR_CONFIG}"

  ros2 launch ground_segmentation "${GROUND_SEGMENTATION_LAUNCH}" \
    rslidar_config:="${RSLIDAR_CONFIG}" &
  PIDS+=("$!")
else
  echo "[start_robosense] Starting RoboSense only. Ground segmentation disabled."
  echo "[start_robosense] RSLIDAR_CONFIG=${RSLIDAR_CONFIG}"

  ros2 run rslidar_sdk rslidar_sdk_node \
    --ros-args \
    -p config_path:="${RSLIDAR_CONFIG}" \
    -r /tf:=/robosense/blocked_tf \
    -r /tf_static:=/robosense/blocked_tf_static &
  PIDS+=("$!")
fi

echo "[start_robosense] Starting Robosense_Torsten launch file: ${POINTCLOUD_TO_LASERSCAN_LAUNCH}"
ros2 launch pointcloud_to_laserscan "${POINTCLOUD_TO_LASERSCAN_LAUNCH}" &
PIDS+=("$!")

wait -n "${PIDS[@]}"
