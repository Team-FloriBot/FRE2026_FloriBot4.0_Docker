#!/bin/bash
set -eo pipefail

source /opt/ros/jazzy/setup.bash
source /ws/install/setup.bash

FRONT_IP="${ROBOSENSE_FRONT_IP:-192.168.1.200}"
REAR_IP="${ROBOSENSE_REAR_IP:-192.168.2.201}"

FRONT_CONFIG="${RSLIDAR_FRONT_CONFIG:-/etc/floribot/robosense/rslidar_front.yaml}"
REAR_CONFIG="${RSLIDAR_REAR_CONFIG:-/etc/floribot/robosense/rslidar_rear.yaml}"

GROUND_SEGMENTATION_ENABLE="${GROUND_SEGMENTATION_ENABLE:-true}"
GROUND_FILTER_AARON_ENABLE="${GROUND_FILTER_AARON_ENABLE:-false}"
GROUND_FILTER_AARON_BUILD_ON_START="${GROUND_FILTER_AARON_BUILD_ON_START:-false}"
POINTCLOUD_TO_LASERSCAN_ENABLE="${POINTCLOUD_TO_LASERSCAN_ENABLE:-true}"

PIDS=()
SHUTDOWN_DONE=false

enabled() {
  case "${1,,}" in
    true|1|yes|on)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

shutdown() {
  if [[ "${SHUTDOWN_DONE}" == "true" ]]; then
    return
  fi

  SHUTDOWN_DONE=true

  echo "[start_robosense] Stopping child processes..."

  for pid in "${PIDS[@]}"; do
    if kill -0 "${pid}" 2>/dev/null; then
      kill "${pid}" 2>/dev/null || true
    fi
  done

  wait 2>/dev/null || true
}

trap shutdown EXIT INT TERM

start_driver() {
  local position="$1"
  local config="$2"
  local ip="$3"

  echo "[start_robosense] Starting AIRY ${position}: device_ip=${ip}, config=${config}"

  ros2 run rslidar_sdk rslidar_sdk_node --ros-args \
    -r __node:="robosense_${position}_driver" \
    -r __ns:="/sensors/robosense/${position}" \
    -p config_path:="${config}" \
    -r /tf:=/robosense/blocked_tf \
    -r /tf_static:=/robosense/blocked_tf_static &

  PIDS+=("$!")
}

start_ground_segmentation() {
  local position="$1"
  local config="/etc/floribot/robosense/ground_segmentation_${position}.yaml"

  echo "[start_robosense] Starting ground segmentation ${position}: config=${config}"

  ros2 run ground_segmentation ground_segmentation_node --ros-args \
    -r __node:="robosense_${position}_ground_segmentation" \
    -r __ns:="/sensors/robosense/${position}" \
    --params-file "${config}" &

  PIDS+=("$!")
}

build_ground_filter_aaron() {
  echo "[start_robosense] Building ground_filter_aaron..."

  (
    cd /ws
    colcon build --packages-select ground_filter_aaron --symlink-install
  )

  source /ws/install/setup.bash
}

start_ground_filter_aaron() {
  local position="$1"
  local config="/etc/floribot/robosense/ground_filter_aaron_${position}.yaml"

  echo "[start_robosense] Starting Aaron ground filter ${position}: config=${config}"

  ros2 launch ground_filter_aaron filter_ground.launch.py \
    namespace:="/sensors/robosense/${position}" \
    node_name:="robosense_${position}_ground_filter_aaron" \
    config:="${config}" &

  PIDS+=("$!")
}

start_laserscan() {
  local position="$1"
  local config="/etc/floribot/robosense/pcl2laserscan_${position}.yaml"

  echo "[start_robosense] Starting pointcloud_to_laserscan ${position}: config=${config}"

  ros2 run pointcloud_to_laserscan pointcloud_to_laserscan_node --ros-args \
    -r __node:="robosense_${position}_pointcloud_to_laserscan" \
    -r __ns:="/sensors/robosense/${position}" \
    --params-file "${config}" \
    -r scan:="/sensors/robosense/${position}/scan" \
    -r debug_pcl:="/sensors/robosense/${position}/debug_points" &

  PIDS+=("$!")
}

if enabled "${GROUND_FILTER_AARON_BUILD_ON_START}"; then
  build_ground_filter_aaron
fi

start_driver front "${FRONT_CONFIG}" "${FRONT_IP}"
start_driver rear "${REAR_CONFIG}" "${REAR_IP}"

if enabled "${GROUND_SEGMENTATION_ENABLE}"; then
  start_ground_segmentation front
  start_ground_segmentation rear
fi

if enabled "${GROUND_FILTER_AARON_ENABLE}"; then
  start_ground_filter_aaron front
  start_ground_filter_aaron rear
fi

if enabled "${POINTCLOUD_TO_LASERSCAN_ENABLE}"; then
  start_laserscan front
  start_laserscan rear
fi

set +e
wait -n "${PIDS[@]}"
EXIT_CODE=$?
set -e

exit "${EXIT_CODE}"
