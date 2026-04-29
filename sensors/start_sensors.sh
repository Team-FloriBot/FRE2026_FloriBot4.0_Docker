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

trap 'kill ${pids[*]} 2>/dev/null || true' SIGINT SIGTERM

wait -n "${pids[@]}"
kill "${pids[@]}" 2>/dev/null || true
