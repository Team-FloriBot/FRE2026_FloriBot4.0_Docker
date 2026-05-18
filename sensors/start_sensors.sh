#!/bin/bash
set -eo pipefail

source /opt/ros/jazzy/setup.bash
source /ws/install/setup.bash

SICK_LAUNCH_FILE="${SICK_LAUNCH_FILE:-sick_tim_5xx.launch.py}"

SICK_FRONT_IP="${SICK_FRONT_IP:-192.168.0.52}"
SICK_REAR_IP="${SICK_REAR_IP:-192.168.0.51}"

SICK_FRONT_FRAME="${SICK_FRONT_FRAME:-sick_front_link}"
SICK_REAR_FRAME="${SICK_REAR_FRAME:-sick_rear_link}"

RS_FRONT_SERIAL="${RS_FRONT_SERIAL:-}"
RS_REAR_SERIAL="${RS_REAR_SERIAL:-}"

XSENS_ENABLE="${XSENS_ENABLE:-true}"
XSENS_SCAN_FOR_DEVICES="${XSENS_SCAN_FOR_DEVICES:-true}"
XSENS_PORT="${XSENS_PORT:-/dev/ttyUSB0}"
XSENS_BAUDRATE="${XSENS_BAUDRATE:-115200}"
XSENS_FRAME_ID="${XSENS_FRAME_ID:-xsens_mti_link}"
XSENS_NAMESPACE="${XSENS_NAMESPACE:-/sensors/xsens}"
XSENS_LOG_LEVEL="${XSENS_LOG_LEVEL:-info}"

pids=()

shutdown()
{
  echo "[sensors] Stopping sensor processes..."
  kill "${pids[@]}" 2>/dev/null || true
  wait 2>/dev/null || true
  exit 0
}

trap shutdown SIGINT SIGTERM

echo "[sensors] Starting SICK front lidar on ${SICK_FRONT_IP}"
ros2 launch sick_scan_xd "${SICK_LAUNCH_FILE}" \
  hostname:="${SICK_FRONT_IP}" \
  nodename:=sick_front \
  frame_id:="${SICK_FRONT_FRAME}" \
  tf_publish_rate:=0 \
  use_generation_timestamp:=false \
  laserscan_topic:=/sensors/scan_front \
  cloud_topic:=/sensors/cloud_front &
pids+=($!)

echo "[sensors] Starting SICK rear lidar on ${SICK_REAR_IP}"
ros2 launch sick_scan_xd "${SICK_LAUNCH_FILE}" \
  hostname:="${SICK_REAR_IP}" \
  nodename:=sick_rear \
  frame_id:="${SICK_REAR_FRAME}" \
  tf_publish_rate:=0 \
  use_generation_timestamp:=false \
  laserscan_topic:=/sensors/scan_rear \
  cloud_topic:=/sensors/cloud_rear &
pids+=($!)

if [ -n "${RS_FRONT_SERIAL}" ]; then
  echo "[sensors] Starting RealSense front, serial ${RS_FRONT_SERIAL}"
  ros2 launch realsense2_camera rs_launch.py \
    camera_namespace:=sensors \
    camera_name:=realsense_front \
    serial_no:="'${RS_FRONT_SERIAL}'" \
    enable_color:=true \
    enable_depth:=true \
    publish_tf:=false \
    align_depth.enable:=true &
  pids+=($!)
else
  echo "[sensors] RealSense front disabled because RS_FRONT_SERIAL is empty"
fi

if [ -n "${RS_REAR_SERIAL}" ]; then
  echo "[sensors] Starting RealSense rear, serial ${RS_REAR_SERIAL}"
  ros2 launch realsense2_camera rs_launch.py \
    camera_namespace:=sensors \
    camera_name:=realsense_rear \
    serial_no:="'${RS_REAR_SERIAL}'" \
    enable_color:=true \
    enable_depth:=true \
    publish_tf:=false \
    align_depth.enable:=true &
  pids+=($!)
else
  echo "[sensors] RealSense rear disabled because RS_REAR_SERIAL is empty"
fi

if [ "${XSENS_ENABLE}" = "true" ] || [ "${XSENS_ENABLE}" = "1" ]; then
  echo "[sensors] Starting Xsens MTi IMU"
  echo "[sensors] Xsens namespace: ${XSENS_NAMESPACE}"
  echo "[sensors] Xsens port: ${XSENS_PORT}, baudrate: ${XSENS_BAUDRATE}, scan_for_devices: ${XSENS_SCAN_FOR_DEVICES}"

  xsens_args=(
    --ros-args
    --params-file "$(ros2 pkg prefix xsens_mti_ros2_driver)/share/xsens_mti_ros2_driver/param/xsens_mti_node.yaml"
    -r __ns:="${XSENS_NAMESPACE}"
    -p scan_for_devices:="${XSENS_SCAN_FOR_DEVICES}"
    -p port:="${XSENS_PORT}"
    -p baudrate:="${XSENS_BAUDRATE}"
    -p frame_id:="${XSENS_FRAME_ID}"
    -p pub_transform:=false
    --log-level "${XSENS_LOG_LEVEL}"
  )

  ros2 run xsens_mti_ros2_driver xsens_mti_node "${xsens_args[@]}" &
  pids+=($!)
else
  echo "[sensors] Xsens MTi IMU disabled because XSENS_ENABLE=${XSENS_ENABLE}"
fi

echo "[sensors] Started ${#pids[@]} sensor process(es)"
echo "[sensors] Container will stay alive until stopped"

set +e
wait
