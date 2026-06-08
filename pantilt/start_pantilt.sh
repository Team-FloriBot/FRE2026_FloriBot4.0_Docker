#!/bin/bash
set -e

source /opt/ros/jazzy/setup.bash
source /ws/install/setup.bash

PANTILT_LAUNCH_FILE="${PANTILT_LAUNCH_FILE:-aim_and_fire.launch.py}"
PANTILT_DRIVER_ENABLE="${PANTILT_DRIVER_ENABLE:-true}"
PTU_PORT="${PTU_PORT:-/dev/ttyUSB0}"
PTU_BAUD="${PTU_BAUD:-9600}"
PTU_PUBLISHING_RATE="${PTU_PUBLISHING_RATE:-5.0}"

cleanup()
{
    echo "[pantilt] Beende Prozesse ..."

    if [ -n "${DRIVER_PID:-}" ]; then
        kill "${DRIVER_PID}" 2>/dev/null || true
    fi

    if [ -n "${APP_PID:-}" ]; then
        kill "${APP_PID}" 2>/dev/null || true
    fi

    wait 2>/dev/null || true
}

trap cleanup EXIT INT TERM

if [ ! -e "${PTU_PORT}" ]; then
    echo "[pantilt] Warnung: PTU-Port ${PTU_PORT} existiert nicht."
    echo "[pantilt] Prüfe das USB-Mapping in docker-compose.yml."
fi

if [ "${PANTILT_DRIVER_ENABLE}" = "true" ]; then
    echo "[pantilt] Starte FLIR-Treiber auf ${PTU_PORT}"

    ros2 run flir_ptu_driver ptu_node.py \
        --ros-args \
        -p port:="${PTU_PORT}" \
        -p baud:="${PTU_BAUD}" \
        -p publishing_rate:="${PTU_PUBLISHING_RATE}" &

    DRIVER_PID=$!

    sleep 2

    if ! kill -0 "${DRIVER_PID}" 2>/dev/null; then
        echo "[pantilt] Fehler: FLIR-Treiber wurde unmittelbar beendet."
        wait "${DRIVER_PID}"
        exit 1
    fi
fi

echo "[pantilt] Starte aim_and_fire"

ros2 launch aim_and_fire "${PANTILT_LAUNCH_FILE}" &
APP_PID=$!

wait -n
EXIT_CODE=$?

echo "[pantilt] Ein Prozess wurde mit Code ${EXIT_CODE} beendet."
exit "${EXIT_CODE}"
