#!/usr/bin/env bash
set -euo pipefail

GPS_PORT="${GPS_PORT:-auto}"
GPS_DEVICE_PATTERN="${GPS_DEVICE_PATTERN:-u-blox|ublox|ardusimple|zed|f9p|gnss|gps}"
GPS_CONFIG_FILE="${GPS_CONFIG_FILE:-/etc/floribot/gps/zed_f9p_rover.yaml}"
GPS_FRAME_ID="${GPS_FRAME_ID:-gps_link}"
GPS_NODE_NAME="${GPS_NODE_NAME:-ublox_gps_node}"

GPS_FIX_TOPIC="${GPS_FIX_TOPIC:-/sensors/gps/fix}"
GPS_VEL_TOPIC="${GPS_VEL_TOPIC:-/sensors/gps/fix_velocity}"

GPS_RATE="${GPS_RATE:-10.0}"
GPS_NAV_RATE="${GPS_NAV_RATE:-1}"
GPS_DYNAMIC_MODEL="${GPS_DYNAMIC_MODEL:-automotive}"

GPS_SCAN_INTERVAL_SEC="${GPS_SCAN_INTERVAL_SEC:-2}"
GPS_RESTART_DELAY_SEC="${GPS_RESTART_DELAY_SEC:-2}"

NAVSAT_ENABLE="${NAVSAT_ENABLE:-false}"
NAVSAT_FREQUENCY="${NAVSAT_FREQUENCY:-30.0}"
NAVSAT_DELAY="${NAVSAT_DELAY:-1.0}"
NAVSAT_MAGNETIC_DECLINATION_RAD="${NAVSAT_MAGNETIC_DECLINATION_RAD:-0.0}"
NAVSAT_YAW_OFFSET_RAD="${NAVSAT_YAW_OFFSET_RAD:-0.0}"
NAVSAT_ZERO_ALTITUDE="${NAVSAT_ZERO_ALTITUDE:-true}"
NAVSAT_PUBLISH_FILTERED_GPS="${NAVSAT_PUBLISH_FILTERED_GPS:-true}"
NAVSAT_USE_ODOMETRY_YAW="${NAVSAT_USE_ODOMETRY_YAW:-false}"
NAVSAT_WAIT_FOR_DATUM="${NAVSAT_WAIT_FOR_DATUM:-false}"
NAVSAT_BROADCAST_UTM_TRANSFORM="${NAVSAT_BROADCAST_UTM_TRANSFORM:-false}"
NAVSAT_BROADCAST_UTM_TRANSFORM_AS_PARENT_FRAME="${NAVSAT_BROADCAST_UTM_TRANSFORM_AS_PARENT_FRAME:-false}"
NAVSAT_TRANSFORM_TIMEOUT="${NAVSAT_TRANSFORM_TIMEOUT:-0.2}"

NAVSAT_IMU_TOPIC="${NAVSAT_IMU_TOPIC:-/imu/data}"
NAVSAT_ODOM_FILTERED_TOPIC="${NAVSAT_ODOM_FILTERED_TOPIC:-/odometry/filtered}"
NAVSAT_ODOM_GPS_TOPIC="${NAVSAT_ODOM_GPS_TOPIC:-/odometry/gps}"
NAVSAT_FILTERED_GPS_TOPIC="${NAVSAT_FILTERED_GPS_TOPIC:-/gps/filtered}"

GPS_PID=""
NAVSAT_PID=""

is_serial_device() {
  local device="$1"
  local resolved_device=""

  [ -e "$device" ] || return 1

  resolved_device="$(readlink -f "$device" 2>/dev/null || true)"

  [ -n "$resolved_device" ] || return 1
  [ -c "$resolved_device" ] || return 1

  case "$device" in
    /dev/ttyACM* | \
    /dev/ttyUSB* | \
    /dev/serial/by-id/* | \
    /dev/serial/by-path/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

device_candidates() {
  {
    find /dev/serial/by-id \
      -maxdepth 1 \
      -type l \
      2>/dev/null \
      | grep -Ei "$GPS_DEVICE_PATTERN" \
      || true

    find /dev/serial/by-id \
      -maxdepth 1 \
      -type l \
      2>/dev/null \
      || true

    find /dev/serial/by-path \
      -maxdepth 1 \
      -type l \
      2>/dev/null \
      || true

    find /dev \
      -maxdepth 1 \
      \( -name 'ttyACM*' -o -name 'ttyUSB*' \) \
      2>/dev/null \
      || true
  } | awk '!seen[$0]++'
}

detect_gps_device() {
  local candidate=""

  if [ "$GPS_PORT" != "auto" ]; then
    if is_serial_device "$GPS_PORT"; then
      printf '%s\n' "$GPS_PORT"
      return 0
    fi

    echo \
      "GPS_PORT ist gesetzt, aber kein gültiges serielles Gerät: ${GPS_PORT}" \
      >&2

    return 1
  fi

  while IFS= read -r candidate; do
    [ -n "$candidate" ] || continue

    if is_serial_device "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done < <(device_candidates)

  return 1
}

terminate_process() {
  local pid="${1:-}"

  [ -n "$pid" ] || return 0

  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid" 2>/dev/null || true

    for _ in $(seq 1 20); do
      if ! kill -0 "$pid" 2>/dev/null; then
        break
      fi

      sleep 0.1
    done
  fi

  if kill -0 "$pid" 2>/dev/null; then
    kill -KILL "$pid" 2>/dev/null || true
  fi

  wait "$pid" 2>/dev/null || true
}

cleanup() {
  trap - INT TERM EXIT

  terminate_process "$NAVSAT_PID"
  terminate_process "$GPS_PID"

  NAVSAT_PID=""
  GPS_PID=""
}

handle_signal() {
  cleanup
  exit 0
}

start_ublox_node() {
  local device="$1"

  echo "Starte u-blox ZED-F9P:"
  echo "  device:        ${device}"
  echo "  config:        ${GPS_CONFIG_FILE}"
  echo "  node:          ${GPS_NODE_NAME}"
  echo "  frame_id:      ${GPS_FRAME_ID}"
  echo "  rate:          ${GPS_RATE} Hz"
  echo "  nav_rate:      ${GPS_NAV_RATE}"
  echo "  dynamic_model: ${GPS_DYNAMIC_MODEL}"
  echo "  fix:           ${GPS_FIX_TOPIC}"
  echo "  fix_velocity:  ${GPS_VEL_TOPIC}"

  ros2 run ublox_gps ublox_gps_node \
    --ros-args \
    --params-file "$GPS_CONFIG_FILE" \
    -r __node:="$GPS_NODE_NAME" \
    -p device:="$device" \
    -p frame_id:="$GPS_FRAME_ID" \
    -p rate:="$GPS_RATE" \
    -p nav_rate:="$GPS_NAV_RATE" \
    -p dynamic_model:="$GPS_DYNAMIC_MODEL" \
    -r fix:="$GPS_FIX_TOPIC" \
    -r fix_velocity:="$GPS_VEL_TOPIC" &

  GPS_PID=$!
}

start_navsat_transform() {
  echo "Starte navsat_transform_node:"
  echo "  gps/fix:           ${GPS_FIX_TOPIC}"
  echo "  imu:               ${NAVSAT_IMU_TOPIC}"
  echo "  odometry/filtered: ${NAVSAT_ODOM_FILTERED_TOPIC}"
  echo "  odometry/gps:      ${NAVSAT_ODOM_GPS_TOPIC}"
  echo "  gps/filtered:      ${NAVSAT_FILTERED_GPS_TOPIC}"

  ros2 run robot_localization navsat_transform_node \
    --ros-args \
    -p frequency:="$NAVSAT_FREQUENCY" \
    -p delay:="$NAVSAT_DELAY" \
    -p magnetic_declination_radians:="$NAVSAT_MAGNETIC_DECLINATION_RAD" \
    -p yaw_offset:="$NAVSAT_YAW_OFFSET_RAD" \
    -p zero_altitude:="$NAVSAT_ZERO_ALTITUDE" \
    -p publish_filtered_gps:="$NAVSAT_PUBLISH_FILTERED_GPS" \
    -p use_odometry_yaw:="$NAVSAT_USE_ODOMETRY_YAW" \
    -p wait_for_datum:="$NAVSAT_WAIT_FOR_DATUM" \
    -p broadcast_utm_transform:="$NAVSAT_BROADCAST_UTM_TRANSFORM" \
    -p broadcast_utm_transform_as_parent_frame:="$NAVSAT_BROADCAST_UTM_TRANSFORM_AS_PARENT_FRAME" \
    -p transform_timeout:="$NAVSAT_TRANSFORM_TIMEOUT" \
    -r gps/fix:="$GPS_FIX_TOPIC" \
    -r imu:="$NAVSAT_IMU_TOPIC" \
    -r odometry/filtered:="$NAVSAT_ODOM_FILTERED_TOPIC" \
    -r odometry/gps:="$NAVSAT_ODOM_GPS_TOPIC" \
    -r gps/filtered:="$NAVSAT_FILTERED_GPS_TOPIC" &

  NAVSAT_PID=$!
}

wait_for_child() {
  if [ "$NAVSAT_ENABLE" = "true" ]; then
    wait -n "$GPS_PID" "$NAVSAT_PID" || true
  else
    wait "$GPS_PID" || true
  fi
}

if [ ! -f "$GPS_CONFIG_FILE" ]; then
  echo "GPS-Konfigurationsdatei wurde nicht gefunden: ${GPS_CONFIG_FILE}" >&2
  exit 1
fi

if ! ros2 pkg prefix ublox_gps >/dev/null 2>&1; then
  echo "ROS-Paket ublox_gps wurde im Container nicht gefunden." >&2
  exit 1
fi

trap handle_signal INT TERM
trap cleanup EXIT

echo "Starte u-blox-GPS-Geräteerkennung."

while true; do
  GPS_DEVICE=""

  if GPS_DEVICE="$(detect_gps_device)"; then
    echo "GPS-Gerät gefunden: ${GPS_DEVICE}"

    start_ublox_node "$GPS_DEVICE"

    if [ "$NAVSAT_ENABLE" = "true" ]; then
      start_navsat_transform
    fi

    wait_for_child

    echo \
      "GPS- oder NAVSAT-Prozess wurde beendet. Stoppe verbleibende Prozesse." \
      >&2

    terminate_process "$NAVSAT_PID"
    terminate_process "$GPS_PID"

    NAVSAT_PID=""
    GPS_PID=""

    echo "Neustart in ${GPS_RESTART_DELAY_SEC}s." >&2
    sleep "$GPS_RESTART_DELAY_SEC"
  else
    echo \
      "Kein u-blox-GNSS-Gerät gefunden. Neuer Scan in ${GPS_SCAN_INTERVAL_SEC}s." \
      >&2

    sleep "$GPS_SCAN_INTERVAL_SEC"
  fi
done
