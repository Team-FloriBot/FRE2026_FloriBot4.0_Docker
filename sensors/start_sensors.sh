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

wait_for_lidar()
{
  local ip="$1"
  local max_attempts="${2:-30}"  # Standard 30 Sekunden Timeout
  local attempt=0

  echo "[sensors] Waiting for lidar ${ip} (max ${max_attempts}s)"

  until nc -z "${ip}" 2112; do
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
      echo "[sensors] ERROR: Lidar ${ip} not reachable after ${max_attempts} seconds"
      return 1
    fi
    if [ $((attempt % 5)) -eq 0 ]; then
      echo "[sensors] Attempt ${attempt}/${max_attempts}: Still waiting for lidar ${ip}..."
    fi
    sleep 1
  done

  echo "[sensors] Lidar ${ip} is reachable"
  sleep 2  # Extra Wartezeit für vollständige Initialisierung
  return 0
}

wait_for_node()
{
  local node_name="$1"
  local max_attempts="${2:-10}"

  echo "[sensors] Waiting for node ${node_name} to start..."

  for ((attempt=1; attempt<=max_attempts; attempt++)); do
    if ros2 node list | grep -q "${node_name}"; then
      echo "[sensors] Node ${node_name} is running"
      return 0
    fi
    if [ $((attempt % 3)) -eq 0 ]; then
      echo "[sensors] Attempt ${attempt}/${max_attempts}: Waiting for node ${node_name}..."
    fi
    sleep 1
  done

  echo "[sensors] ERROR: Node ${node_name} did not start after ${max_attempts} seconds"
  return 1
}

trap shutdown SIGINT SIGTERM

echo "[sensors] Checking SICK front connectivity"
if ! wait_for_lidar "${SICK_FRONT_IP}"; then
  echo "[sensors] FATAL: Front LiDAR at ${SICK_FRONT_IP} could not be reached. Exiting."
  exit 1
fi

echo "[sensors] Starting SICK front lidar on ${SICK_FRONT_IP}"
ros2 run sick_scan_xd sick_generic_caller ./src/sick_scan_xd/launch/sick_tim_5xx.launch \
  hostname:="${SICK_FRONT_IP}" \
  nodename:=sick_front \
  frame_id:="${SICK_FRONT_FRAME}" \
  tf_publish_rate:=0.0 \
  ros_timestamp_control:=1 \
  laserscan_topic:=/sensors/scan_front \
  cloud_topic:=/sensors/cloud_front \
  --ros-args \
  -r __node:=sick_front \
  -r sw_pll_only_publish:=false &
sleep 1
pids+=($!)

# Warte auf Node
if ! wait_for_node "/sick_front" 10; then
  echo "[sensors] FATAL: sick_front node did not start. Exiting."
  exit 1
fi

echo "[sensors] Checking SICK rear connectivity"
if ! wait_for_lidar "${SICK_REAR_IP}"; then
  echo "[sensors] FATAL: Rear LiDAR at ${SICK_REAR_IP} could not be reached. Exiting."
  exit 1
fi

echo "[sensors] Starting SICK rear lidar on ${SICK_REAR_IP}"
ros2 run sick_scan_xd sick_generic_caller ./src/sick_scan_xd/launch/sick_tim_5xx.launch \
  hostname:="${SICK_REAR_IP}" \
  nodename:=sick_rear \
  frame_id:="${SICK_REAR_FRAME}" \
  tf_publish_rate:=0.0 \
  ros_timestamp_control:=1 \
  laserscan_topic:=/sensors/scan_rear \
  --ros-args \
  -r __node:=sick_rear \
  -r sw_pll_only_publish:=false &
sleep 1
pids+=($!)

# Warte auf Node
if ! wait_for_node "/sick_rear" 10; then
  echo "[sensors] FATAL: sick_rear node did not start. Exiting."
  exit 1
fi

if [ -n "${RS_FRONT_SERIAL}" ]; then
  echo "[sensors] Starting RealSense front, serial ${RS_FRONT_SERIAL}"
  ros2 launch realsense2_camera rs_launch.py \
    camera_namespace:=sensors \
    camera_name:=realsense_front \
    serial_no:="'${RS_FRONT_SERIAL}'" \
    enable_rgbd:=true \
    enable_sync:=true \
    align_depth.enable:=true \
    enable_color:=true \
    enable_depth:=true \
    color_module.profile:=640x480x30 \
    publish_tf:=false &
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
