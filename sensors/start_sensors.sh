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

RS_FRONT_CONFIG_FILE="${RS_FRONT_CONFIG_FILE:-/etc/floribot/object_detection/detector_params.yaml}"

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

  if [ "${#pids[@]}" -gt 0 ]; then
    kill "${pids[@]}" 2>/dev/null || true
  fi

  wait 2>/dev/null || true
  exit 0
}

trap shutdown SIGINT SIGTERM

echo "[sensors] Starting SICK front lidar on ${SICK_FRONT_IP}"
echo "[sensors] Starting SICK rear lidar on ${SICK_REAR_IP}"

ros2 launch sick_scan_xd laser.launch.py &
pids+=($!)

sleep 1

if [ -n "${RS_FRONT_SERIAL}" ]; then
  echo "[sensors] Starting RealSense front"
  echo "[sensors] RealSense serial: ${RS_FRONT_SERIAL}"
  echo "[sensors] RealSense config: ${RS_FRONT_CONFIG_FILE}"

  if [ ! -f "${RS_FRONT_CONFIG_FILE}" ]; then
    echo "[sensors] ERROR: RealSense config file does not exist:"
    echo "[sensors] ERROR: ${RS_FRONT_CONFIG_FILE}"
    shutdown
    exit 1
  fi

  if [ ! -r "${RS_FRONT_CONFIG_FILE}" ]; then
    echo "[sensors] ERROR: RealSense config file is not readable:"
    echo "[sensors] ERROR: ${RS_FRONT_CONFIG_FILE}"
    shutdown
    exit 1
  fi

  ros2 launch realsense2_camera rs_launch.py \
    camera_namespace:=sensors \
    camera_name:=realsense_front \
    serial_no:="'${RS_FRONT_SERIAL}'" \
    config_file:="${RS_FRONT_CONFIG_FILE}" &

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
  echo "[sensors] Xsens port: ${XSENS_PORT}"
  echo "[sensors] Xsens baudrate: ${XSENS_BAUDRATE}"
  echo "[sensors] Xsens scan_for_devices: ${XSENS_SCAN_FOR_DEVICES}"

  ros2 launch xsens_mti_ros2_driver imu.launch.py \
    xsens_namespace:="${XSENS_NAMESPACE}" &

  pids+=($!)
else
  echo "[sensors] Xsens MTi IMU disabled because XSENS_ENABLE=${XSENS_ENABLE}"
fi

echo "[sensors] Started ${#pids[@]} sensor process(es)"
echo "[sensors] Container will stay alive until stopped"

set +e
wait
exit_code=$?

echo "[sensors] A sensor process exited with status ${exit_code}"
shutdown
