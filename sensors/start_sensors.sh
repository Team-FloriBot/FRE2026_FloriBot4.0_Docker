#!/bin/bash
set -eo pipefail

source /opt/ros/jazzy/setup.bash
source /ws/install/setup.bash

SICK_LAUNCH_FILE="${SICK_LAUNCH_FILE:-sick_tim_5xx.launch.py}"

SICK_FRONT_IP="${SICK_FRONT_IP:-192.168.0.52}"
SICK_REAR_IP="${SICK_REAR_IP:-192.168.0.51}"

SICK_FRONT_FRAME="${SICK_FRONT_FRAME:-sick_front_link}"
SICK_REAR_FRAME="${SICK_REAR_FRAME:-sick_rear_link}"

RS_FRONT_SERIAL="${RS_FRONT_SERIAL:-947522071563}"
RS_REAR_SERIAL="${RS_REAR_SERIAL:-}"

XSENS_ENABLE="${XSENS_ENABLE:-true}"
XSENS_SCAN_FOR_DEVICES="${XSENS_SCAN_FOR_DEVICES:-true}"
XSENS_PORT="${XSENS_PORT:-/dev/ttyUSB0}"
XSENS_BAUDRATE="${XSENS_BAUDRATE:-115200}"
XSENS_FRAME_ID="${XSENS_FRAME_ID:-xsens_mti_link}"
XSENS_NAMESPACE="${XSENS_NAMESPACE:-/sensors/xsens}"
XSENS_LOG_LEVEL="${XSENS_LOG_LEVEL:-info}"

pids=()

ros2 launch sick_scan_xd "${SICK_LAUNCH_FILE}" \
  hostname:="${SICK_FRONT_IP}" \
  nodename:=sick_front \
  frame_id:="${SICK_FRONT_FRAME}" \
  laserscan_topic:=/sensors/scan_front \
  cloud_topic:=/sensors/cloud_front &
pids+=($!)

ros2 launch sick_scan_xd "${SICK_LAUNCH_FILE}" \
  hostname:="${SICK_REAR_IP}" \
  nodename:=sick_rear \
  frame_id:="${SICK_REAR_FRAME}" \
  laserscan_topic:=/sensors/scan_rear \
  cloud_topic:=/sensors/cloud_rear &
pids+=($!)

if [ -n "${RS_FRONT_SERIAL}" ]; then
  ros2 launch realsense2_camera rs_launch.py \
    camera_namespace:=sensors \
    camera_name:=realsense_front \
    serial_no:="'${RS_FRONT_SERIAL}'" \
    enable_color:=true \
    enable_depth:=true \
    align_depth.enable:=true &
  pids+=($!)
fi

if [ -n "${RS_REAR_SERIAL}" ]; then
  ros2 launch realsense2_camera rs_launch.py \
    camera_namespace:=sensors \
    camera_name:=realsense_rear \
    serial_no:="'${RS_REAR_SERIAL}'" \
    enable_color:=true \
    enable_depth:=true \
    align_depth.enable:=true &
  pids+=($!)
fi

if [ "${XSENS_ENABLE}" = "true" ] || [ "${XSENS_ENABLE}" = "1" ]; then
  xsens_args=(
    --ros-args
    --params-file "$(ros2 pkg prefix xsens_mti_ros2_driver)/share/xsens_mti_ros2_driver/param/xsens_mti_node.yaml"
    -r __ns:="${XSENS_NAMESPACE}"
    -p scan_for_devices:="${XSENS_SCAN_FOR_DEVICES}"
    -p port:="${XSENS_PORT}"
    -p baudrate:="${XSENS_BAUDRATE}"
    -p frame_id:="${XSENS_FRAME_ID}"
    --log-level "${XSENS_LOG_LEVEL}"
  )

  ros2 run xsens_mti_ros2_driver xsens_mti_node "${xsens_args[@]}" &
  pids+=($!)
fi

trap 'kill ${pids[*]} 2>/dev/null || true' SIGINT SIGTERM

wait -n "${pids[@]}"
kill "${pids[@]}" 2>/dev/null || true
