#!/bin/bash
set -e

source /opt/ros/jazzy/setup.bash

if [ -f /ws/install/setup.bash ]; then
    source /ws/install/setup.bash
fi

PANTILT_LAUNCH_FILE="${PANTILT_LAUNCH_FILE:-aim_and_fire.launch.py}"

if [ -n "${PTU_PORT:-}" ] && [ ! -e "${PTU_PORT}" ]; then
    echo "[pantilt] Warnung: PTU_PORT=${PTU_PORT} existiert im Container nicht. Prüfe compose/.env und USB-Mapping."
fi

echo "[pantilt] Starte PanTilt mit Launch-Datei: ${PANTILT_LAUNCH_FILE}"

exec ros2 launch aim_and_fire "${PANTILT_LAUNCH_FILE}"
