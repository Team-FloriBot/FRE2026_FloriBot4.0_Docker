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

# ==========================================
# FUNKTIONEN: LiDAR Prüfung & Launch
# ==========================================

wait_for_lidar()
{
  local ip="$1"
  local max_attempts="${2:-45}" # 45 Sekunden Timeout
  local attempt=0

  echo "[sensors] Waiting for lidar ${ip} to be fully ready (network + firmware)..."

  while [ $attempt -lt $max_attempts ]; do
    attempt=$((attempt + 1))

    # Prüfe zuerst, ob der Port überhaupt offen ist
    if nc -z -w 1 "${ip}" 2112 2>/dev/null; then
      
      # Sende CoLa-Befehl für den Gerätestatus und bereinige STX/ETX Zeichen
      local response
      response=$(echo -e "\x02sRN STlms\x03" | nc -w 2 "${ip}" 2112 2>/dev/null | tr -d '\x02\x03')
      
      # Überprüfe, ob die Antwort mit "sRA STlms 0" endet (0 = Kein Fehler / Bereit)
      if [[ "$response" == *"sRA STlms 0"* ]]; then
        echo "[sensors] Success: Lidar ${ip} firmware reports READY status."
        return 0
      else
        if [ $((attempt % 5)) -eq 0 ]; then
          echo "[sensors] Attempt ${attempt}/${max_attempts}: Port open, but firmware status not ready yet (Response: ${response:-Timeout})"
        fi
      fi
    else
      if [ $((attempt % 5)) -eq 0 ]; then
        echo "[sensors] Attempt ${attempt}/${max_attempts}: Network port 2112 closed..."
      fi
    fi
    
    sleep 1
  done

  echo "[sensors] ERROR: Lidar ${ip} did not reach READY status within ${max_attempts}s"
  return 1
}

launch_lidar_node()
{
  local ip="$1"
  local frame="$2"
  local node_name="$3"
  local scan_topic="$4"
  local cloud_topic="$5" # Optional
  local max_retries=3
  local retry=0

  while [ $retry -lt $max_retries ]; do
    retry=$((retry + 1))
    echo "[sensors] Launching ROS 2 node for ${node_name} (Attempt ${retry}/${max_retries})..."

    # Argumente dynamisch aufbauen
    local cmd=(ros2 run sick_scan_xd sick_generic_caller ./src/sick_scan_xd/launch/sick_tim_5xx.launch)
    cmd+=(hostname:="${ip}")
    cmd+=(nodename:="${node_name}")
    cmd+=(frame_id:="${frame}")
    cmd+=(tf_publish_rate:=0.0)
    cmd+=(ros_timestamp_control:=1)
    cmd+=(laserscan_topic:="${scan_topic}")
    cmd+=(cloud_topic:="${cloud_topic}")

    cmd+=(--ros-args -r __node:="${node_name}" -p sw_pll_only_publish:=false)

    # Starte den Treiber im Hintergrund
    "${cmd[@]}" &
    
    local pid=$!
    sleep 3 # Warte 3 Sekunden, um zu sehen, ob der Knoten abstürzt

    # Prüfe, ob der Prozess im Hintergrund noch läuft
    if kill -0 $pid 2>/dev/null; then
      echo "[sensors] Node ${node_name} started successfully (PID: $pid)"
      pids+=($pid) # Füge PID zum globalen Array hinzu
      return 0
    else
      echo "[sensors] WARNING: Node ${node_name} died immediately after launch!"
    fi
  done

  echo "[sensors] FATAL: Failed to launch ${node_name} after ${max_retries} attempts."
  return 1
}

# ==========================================
# HAUPTABLAUF: Sensoren starten
# ==========================================

# 1. Front LiDAR
echo "[sensors] Checking SICK front connectivity and firmware..."
if wait_for_lidar "${SICK_FRONT_IP}"; then
  # Hier übergeben wir zusätzlich das cloud_topic
  if ! launch_lidar_node "${SICK_FRONT_IP}" "${SICK_FRONT_FRAME}" "sick_front" "/sensors/scan_front" "/sensors/cloud_front"; then
    exit 1
  fi
else
  echo "[sensors] FATAL: Front LiDAR unavailable. Exiting."
  exit 1
fi

# 2. Rear LiDAR
echo "[sensors] Checking SICK rear connectivity and firmware..."
if wait_for_lidar "${SICK_REAR_IP}"; then
  # Kein cloud_topic für den Rear-LiDAR
  if ! launch_lidar_node "${SICK_REAR_IP}" "${SICK_REAR_FRAME}" "sick_rear" "/sensors/scan_rear" ""; then
    exit 1
  fi
else
  echo "[sensors] FATAL: Rear LiDAR unavailable. Exiting."
  exit 1
fi

# 3. RealSense Front
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

# 4. RealSense Rear
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

# 5. Xsens IMU
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