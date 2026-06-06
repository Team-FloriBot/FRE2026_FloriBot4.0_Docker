#!/usr/bin/env bash
set -euo pipefail

source /opt/ros/jazzy/setup.bash

if [ -f /ws/install/setup.bash ]; then
  source /ws/install/setup.bash
fi

GPS_PORT="${GPS_PORT:-auto}"
GPS_BAUD="${GPS_BAUD:-auto}"
GPS_BAUD_CANDIDATES="${GPS_BAUD_CANDIDATES:-38400 115200 9600 57600}"
GPS_FRAME_ID="${GPS_FRAME_ID:-gps_link}"

GPS_FIX_TOPIC="${GPS_FIX_TOPIC:-/sensors/gps/fix}"
GPS_VEL_TOPIC="${GPS_VEL_TOPIC:-/sensors/gps/vel}"
GPS_TIME_REF_TOPIC="${GPS_TIME_REF_TOPIC:-/sensors/gps/time_reference}"
GPS_HEADING_TOPIC="${GPS_HEADING_TOPIC:-/sensors/gps/heading}"

SCAN_INTERVAL_SEC="${GPS_SCAN_INTERVAL_SEC:-2}"
SCAN_TIMEOUT_SEC="${GPS_SCAN_TIMEOUT_SEC:-5}"

NAVSAT_ENABLE="${NAVSAT_ENABLE:-true}"
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

is_serial_device() {
  local dev="$1"

  [ -e "$dev" ] || return 1
  [ -c "$(readlink -f "$dev")" ] || return 1

  case "$dev" in
    /dev/ttyACM*|/dev/ttyUSB*|/dev/serial/by-id/*|/dev/serial/by-path/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

device_candidates() {
  {
    find /dev/serial/by-id -maxdepth 1 -type l 2>/dev/null | grep -Ei 'u-blox|ublox|ardusimple|zed|f9p|gnss|gps' || true
    find /dev/serial/by-id -maxdepth 1 -type l 2>/dev/null || true
    ls /dev/ttyACM* /dev/ttyUSB* 2>/dev/null || true
  } | awk '!seen[$0]++'
}

probe_nmea() {
  local dev="$1"
  local baud="$2"

  python3 - "$dev" "$baud" "$SCAN_TIMEOUT_SEC" <<'PY'
import sys
import time
import serial

port = sys.argv[1]
baud = int(sys.argv[2])
timeout_s = float(sys.argv[3])

nmea_markers = (
    "GGA",
    "RMC",
    "GLL",
    "VTG",
    "GSA",
    "GSV",
)

deadline = time.time() + timeout_s

try:
    with serial.Serial(port, baudrate=baud, timeout=0.25) as ser:
        ser.reset_input_buffer()

        while time.time() < deadline:
            raw = ser.readline()
            if not raw:
                continue

            try:
                line = raw.decode("ascii", errors="ignore").strip()
            except Exception:
                continue

            if not line.startswith("$"):
                continue

            if len(line) >= 6 and any(marker in line[3:6] for marker in nmea_markers):
                print(line)
                sys.exit(0)

except Exception as exc:
    sys.stderr.write(f"{port} @ {baud}: {exc}\n")

sys.exit(1)
PY
}

detect_gps() {
  if [ "$GPS_PORT" != "auto" ]; then
    if ! is_serial_device "$GPS_PORT"; then
      echo "GPS_PORT ist gesetzt, aber kein gültiges serielles Device: $GPS_PORT" >&2
      return 1
    fi

    if [ "$GPS_BAUD" = "auto" ]; then
      for baud in $GPS_BAUD_CANDIDATES; do
        if probe_nmea "$GPS_PORT" "$baud" >/dev/null 2>&1; then
          echo "$GPS_PORT $baud"
          return 0
        fi
      done
      return 1
    else
      echo "$GPS_PORT $GPS_BAUD"
      return 0
    fi
  fi

  while IFS= read -r dev; do
    is_serial_device "$dev" || continue

    if [ "$GPS_BAUD" = "auto" ]; then
      for baud in $GPS_BAUD_CANDIDATES; do
        echo "Teste GNSS/NMEA: $dev @ $baud" >&2
        if probe_nmea "$dev" "$baud" >/dev/null 2>&1; then
          echo "$dev $baud"
          return 0
        fi
      done
    else
      echo "Teste GNSS/NMEA: $dev @ $GPS_BAUD" >&2
      if probe_nmea "$dev" "$GPS_BAUD" >/dev/null 2>&1; then
        echo "$dev $GPS_BAUD"
        return 0
      fi
    fi
  done < <(device_candidates)

  return 1
}

cleanup_children() {
  local pids=("$@")

  for pid in "${pids[@]}"; do
    if [ -n "${pid}" ] && kill -0 "${pid}" 2>/dev/null; then
      kill "${pid}" 2>/dev/null || true
    fi
  done

  for pid in "${pids[@]}"; do
    if [ -n "${pid}" ]; then
      wait "${pid}" 2>/dev/null || true
    fi
  done
}

echo "Starte GPS-Autodetect."

while true; do
  if result="$(detect_gps)"; then
    DETECTED_PORT="$(echo "$result" | awk '{print $1}')"
    DETECTED_BAUD="$(echo "$result" | awk '{print $2}')"

    echo "GPS gefunden: ${DETECTED_PORT} @ ${DETECTED_BAUD}"
    echo "Publiziere NMEA/GNSS:"
    echo "  fix:            ${GPS_FIX_TOPIC}"
    echo "  vel:            ${GPS_VEL_TOPIC}"
    echo "  time_reference: ${GPS_TIME_REF_TOPIC}"
    echo "  heading:        ${GPS_HEADING_TOPIC}"
    echo "  frame_id:       ${GPS_FRAME_ID}"

    ros2 run nmea_navsat_driver nmea_serial_driver \
      --ros-args \
      -p port:="${DETECTED_PORT}" \
      -p baud:="${DETECTED_BAUD}" \
      -p frame_id:="${GPS_FRAME_ID}" \
      -r fix:="${GPS_FIX_TOPIC}" \
      -r vel:="${GPS_VEL_TOPIC}" \
      -r time_reference:="${GPS_TIME_REF_TOPIC}" \
      -r heading:="${GPS_HEADING_TOPIC}" &

    NMEA_PID=$!

    if [ "${NAVSAT_ENABLE}" = "true" ]; then
      echo "Starte navsat_transform_node:"
      echo "  gps/fix:           ${GPS_FIX_TOPIC}"
      echo "  imu:               ${NAVSAT_IMU_TOPIC}"
      echo "  odometry/filtered: ${NAVSAT_ODOM_FILTERED_TOPIC}"
      echo "  odometry/gps:      ${NAVSAT_ODOM_GPS_TOPIC}"
      echo "  filtered/gps:      ${NAVSAT_FILTERED_GPS_TOPIC}"

      ros2 run robot_localization navsat_transform_node \
        --ros-args \
        -p frequency:="${NAVSAT_FREQUENCY}" \
        -p delay:="${NAVSAT_DELAY}" \
        -p magnetic_declination_radians:="${NAVSAT_MAGNETIC_DECLINATION_RAD}" \
        -p yaw_offset:="${NAVSAT_YAW_OFFSET_RAD}" \
        -p zero_altitude:="${NAVSAT_ZERO_ALTITUDE}" \
        -p publish_filtered_gps:="${NAVSAT_PUBLISH_FILTERED_GPS}" \
        -p use_odometry_yaw:="${NAVSAT_USE_ODOMETRY_YAW}" \
        -p wait_for_datum:="${NAVSAT_WAIT_FOR_DATUM}" \
        -p broadcast_utm_transform:="${NAVSAT_BROADCAST_UTM_TRANSFORM}" \
        -p broadcast_utm_transform_as_parent_frame:="${NAVSAT_BROADCAST_UTM_TRANSFORM_AS_PARENT_FRAME}" \
        -p transform_timeout:="${NAVSAT_TRANSFORM_TIMEOUT}" \
        -r gps/fix:="${GPS_FIX_TOPIC}" \
        -r imu:="${NAVSAT_IMU_TOPIC}" \
        -r odometry/filtered:="${NAVSAT_ODOM_FILTERED_TOPIC}" \
        -r odometry/gps:="${NAVSAT_ODOM_GPS_TOPIC}" \
        -r gps/filtered:="${NAVSAT_FILTERED_GPS_TOPIC}" &

      NAVSAT_PID=$!

      trap 'cleanup_children "${NMEA_PID}" "${NAVSAT_PID}"' INT TERM EXIT

      wait -n "${NMEA_PID}" "${NAVSAT_PID}" || true

      echo "GPS- oder NAVSAT-Node wurde beendet. Stoppe verbleibende Prozesse und starte Autodetect neu." >&2
      cleanup_children "${NMEA_PID}" "${NAVSAT_PID}"
      trap - INT TERM EXIT
    else
      trap 'cleanup_children "${NMEA_PID}"' INT TERM EXIT

      wait "${NMEA_PID}" || true

      echo "GPS-Node wurde beendet. Starte Autodetect neu." >&2
      cleanup_children "${NMEA_PID}"
      trap - INT TERM EXIT
    fi
  fi

  echo "Kein GNSS/NMEA-Gerät gefunden. Neuer Scan in ${SCAN_INTERVAL_SEC}s." >&2
  sleep "$SCAN_INTERVAL_SEC"
done
