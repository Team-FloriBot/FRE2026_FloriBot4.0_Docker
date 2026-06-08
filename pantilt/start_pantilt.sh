#!/bin/bash
set -e

source /opt/ros/jazzy/setup.bash
source /ws/install/setup.bash

PANTILT_LAUNCH_FILE="${PANTILT_LAUNCH_FILE:-aim_and_fire.launch.py}"
PANTILT_DRIVER_ENABLE="${PANTILT_DRIVER_ENABLE:-true}"
PTU_PORT="${PTU_PORT:-/dev/ttyUSB0}"

cleanup() {
    kill "${DRIVER_PID:-}" "${APP_PID:-}" 2>/dev/null || true
    wait 2>/dev/null || true
}

trap cleanup EXIT INT TERM

if [[ "${PANTILT_DRIVER_ENABLE}" == "true" ]]; then
    ros2 run flir_ptu_driver <TREIBER_EXECUTABLE> \
        --ros-args -p <PORT_PARAMETER>:="${PTU_PORT}" &

    DRIVER_PID=$!
fi

ros2 launch aim_and_fire "${PANTILT_LAUNCH_FILE}" &
APP_PID=$!

wait -n
