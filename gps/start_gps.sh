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
    # Stabile Symlinks bevorzugen. Bei u-blox/ArduSimple ist das meist am saubersten.
    find /dev/serial/by-id -maxdepth 1 -type l 2>/dev/null | grep -Ei 'u-blox|ublox|ardusimple|zed|f9p|gnss|gps' || true
    find /dev/serial/by-id -maxdepth 1 -type l 2>/dev/null || true

    # Fallback: klassische USB-Serial-Geräte
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
    "GGA",  # fix data
    "RMC",  # recommended minimum data
    "GLL",  # lat/lon
    "VTG",  # course / ground speed
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

            # Beispiele:
            # $GNGGA,...
            # $GNRMC,...
            # $GPGGA,...
            # $GARMC,...
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

echo "Starte GPS-Autodetect."

while true; do
  if result="$(detect_gps)"; then
    DETECTED_PORT="$(echo "$result" | awk '{print $1}')"
    DETECTED_BAUD="$(echo "$result" | awk '{print $2}')"

    echo "GPS gefunden: ${DETECTED_PORT} @ ${DETECTED_BAUD}"
    echo "Publiziere:"
    echo "  fix:            ${GPS_FIX_TOPIC}"
    echo "  vel:            ${GPS_VEL_TOPIC}"
    echo "  time_reference: ${GPS_TIME_REF_TOPIC}"
    echo "  heading:        ${GPS_HEADING_TOPIC}"
    echo "  frame_id:       ${GPS_FRAME_ID}"

    exec ros2 run nmea_navsat_driver nmea_serial_driver \
      --ros-args \
      -p port:="${DETECTED_PORT}" \
      -p baud:="${DETECTED_BAUD}" \
      -p frame_id:="${GPS_FRAME_ID}" \
      -r fix:="${GPS_FIX_TOPIC}" \
      -r vel:="${GPS_VEL_TOPIC}" \
      -r time_reference:="${GPS_TIME_REF_TOPIC}" \
      -r heading:="${GPS_HEADING_TOPIC}"
  fi

  echo "Kein GNSS/NMEA-Gerät gefunden. Neuer Scan in ${SCAN_INTERVAL_SEC}s." >&2
  sleep "$SCAN_INTERVAL_SEC"
done
