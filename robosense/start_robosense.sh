#!/bin/bash
set -eo pipefail

source /opt/ros/jazzy/setup.bash
source /ws/install/setup.bash

RSLIDAR_CONFIG="${RSLIDAR_CONFIG:-/ws/install/rslidar_sdk/share/rslidar_sdk/config/config.yaml}"
GROUND_SEGMENTATION_CONFIG="${GROUND_SEGMENTATION_CONFIG:-/ws/install/ground_segmentation/share/ground_segmentation/config/ground_segmentation.yaml}"
GROUND_SEGMENTATION_ENABLE="${GROUND_SEGMENTATION_ENABLE:-true}"

pids=()

shutdown()
{
  kill "${pids[@]}" 2>/dev/null || true
  wait 2>/dev/null || true
  exit 0
}

trap shutdown SIGINT SIGTERM

# Robosense must not contribute transforms to the robot-wide TF tree.
# Keep point-cloud frame_ids intact, but isolate any current or future TF publishers.
ros2 run rslidar_sdk rslidar_sdk_node \
  --ros-args \
  -p config_path:="${RSLIDAR_CONFIG}" \
  -r /tf:=/robosense/blocked_tf \
  -r /tf_static:=/robosense/blocked_tf_static &

pids+=($!)

sleep 2

if [ "${GROUND_SEGMENTATION_ENABLE}" = "true" ] || \
   [ "${GROUND_SEGMENTATION_ENABLE}" = "1" ]; then

  ros2 run ground_segmentation ground_segmentation_node \
    --ros-args \
    --params-file "${GROUND_SEGMENTATION_CONFIG}" \
    -r /tf:=/robosense/blocked_tf \
    -r /tf_static:=/robosense/blocked_tf_static &

  pids+=($!)
fi

wait
