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
  echo "[sensors] Waiting for lidar TCP 2112 on ${ip}"
  until nc -z "${ip}" 2112; do
    sleep 1
  done
  echo "[sensors] Lidar ${ip} is reachable on TCP 2112"
  sleep 3
}

# Neue Wrapper-Funktion für den Lidar-Launch mit Node-Überprüfung
launch_lidar_with_retry()
{
  local ip="$1"
  local node_name="$2"
  # Überspringe die ersten zwei Argumente, der Rest ist der eigentliche ROS-Befehl
  shift 2
  local ros_cmd=("$@")

  # 1. Stelle sicher, dass das Gerät physisch im Netzwerk da ist
  wait_for_lidar "${ip}"

  while true; do
    echo "[sensors] Starting Lidar Node /${node_name} on ${ip}..."
    
    # 2. Starte den ROS-Befehl im Hintergrund
    "${ros_cmd[@]}" &
    local child_pid=$!

    local node_found=false
    local timeout_sec=10

    echo "[sensors] Waiting up to ${timeout_sec}s for node /${node_name} to appear in ROS graph..."
    
    # 3. Überprüfe zyklisch den ROS 2 Graphen
    for (( i=1; i<=timeout_sec; i++ )); do
      # In einem if-Statement führt grep bei Nicht-Finden nicht zum Skript-Abbruch (trotz set -e)
      if ros2 node list 2>/dev/null | grep -q "^/${node_name}$"; then
        node_found=true
        break
      fi
      sleep 1
    done

    # 4. Auswertung
    if [ "$node_found" = true ]; then
      echo "[sensors] SUCCESS: Node /${node_name} is active."
      pids+=($child_pid)
      break # Raus aus der Retry-Schleife
    else
      echo "[sensors] ERROR: Node /${node_name} did not appear in time. Retrying..."
      # Schieße den hängenden Prozess ab
      kill -9 $child_pid 2>/dev/null || true
      wait $child_pid 2>/dev/null || true
      sleep 2
    fi
  done
}

trap shutdown SIGINT SIGTERM

echo "[sensors] Initializing SICK front lidar"
launch_lidar_with_retry "${SICK_FRONT_IP}" "sick_front" \
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
  -p sw_pll_only_publish:=false

echo "[sensors] Initializing SICK rear lidar"
launch_lidar_with_retry "${SICK_REAR_IP}" "sick_rear" \
  ros2 run sick_scan_xd sick_generic_caller ./src/sick_scan_xd/launch/sick_tim_5xx.launch \
  hostname:="${SICK_REAR_IP}" \
  nodename:=sick_rear \
  frame_id:="${SICK_REAR_FRAME}" \
  tf_publish_rate:=0.0 \
  ros_timestamp_control:=1 \
  laserscan_topic:=/sensors/scan_rear \
  cloud_topic:=/sensors/cloud_rear \
  --ros-args \
  -r __node:=sick_rear \
  -p sw_pll_only_publish:=false

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