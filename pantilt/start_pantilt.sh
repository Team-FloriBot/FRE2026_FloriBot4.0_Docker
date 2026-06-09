```bash
#!/bin/bash
set -Eeuo pipefail

source /opt/ros/jazzy/setup.bash
source /ws/install/setup.bash

PANTILT_LAUNCH_FILE="${PANTILT_LAUNCH_FILE:-aim_and_fire.launch.py}"
PANTILT_DRIVER_ENABLE="${PANTILT_DRIVER_ENABLE:-true}"
PTU_REFERENCE_ENABLE="${PTU_REFERENCE_ENABLE:-true}"

PTU_PORT="${PTU_PORT:-/dev/ttyUSB0}"
PTU_BAUD="${PTU_BAUD:-9600}"
PTU_PUBLISHING_RATE="${PTU_PUBLISHING_RATE:-5.0}"

DRIVER_PID=""
APP_PID=""
REFERENCE_PID=""

cleanup()
{
    local exit_code=$?

    trap - EXIT INT TERM

    echo "[pantilt] Beende Prozesse ..."

    if [ -n "${REFERENCE_PID}" ] && kill -0 "${REFERENCE_PID}" 2>/dev/null; then
        echo "[pantilt] Beende PTU-Referenz-Service ..."
        kill -TERM "${REFERENCE_PID}" 2>/dev/null || true
    fi

    if [ -n "${APP_PID}" ] && kill -0 "${APP_PID}" 2>/dev/null; then
        echo "[pantilt] Beende aim_and_fire ..."
        kill -TERM "${APP_PID}" 2>/dev/null || true
    fi

    if [ -n "${DRIVER_PID}" ] && kill -0 "${DRIVER_PID}" 2>/dev/null; then
        echo "[pantilt] Beende FLIR-Treiber ..."
        kill -TERM "${DRIVER_PID}" 2>/dev/null || true
    fi

    wait "${REFERENCE_PID}" 2>/dev/null || true
    wait "${APP_PID}" 2>/dev/null || true
    wait "${DRIVER_PID}" 2>/dev/null || true

    echo "[pantilt] Alle Prozesse wurden beendet."

    exit "${exit_code}"
}

handle_signal()
{
    echo "[pantilt] Stoppsignal empfangen."
    exit 0
}

check_process()
{
    local process_name="$1"
    local process_pid="$2"

    if ! kill -0 "${process_pid}" 2>/dev/null; then
        echo "[pantilt] Fehler: ${process_name} wurde unmittelbar beendet."

        set +e
        wait "${process_pid}"
        local process_exit_code=$?
        set -e

        echo "[pantilt] ${process_name} Exit-Code: ${process_exit_code}"
        exit "${process_exit_code}"
    fi
}

trap cleanup EXIT
trap handle_signal INT TERM

echo "[pantilt] Konfiguration:"
echo "[pantilt]   Launch-Datei:       ${PANTILT_LAUNCH_FILE}"
echo "[pantilt]   PTU-Port:           ${PTU_PORT}"
echo "[pantilt]   PTU-Baudrate:       ${PTU_BAUD}"
echo "[pantilt]   Publishing-Rate:     ${PTU_PUBLISHING_RATE}"
echo "[pantilt]   FLIR-Treiber:        ${PANTILT_DRIVER_ENABLE}"
echo "[pantilt]   Referenz-Service:    ${PTU_REFERENCE_ENABLE}"

if [ ! -e "${PTU_PORT}" ]; then
    echo "[pantilt] Warnung: PTU-Port ${PTU_PORT} existiert nicht."
    echo "[pantilt] Prüfe das USB-Mapping in docker-compose.yml."
fi

if [ "${PANTILT_DRIVER_ENABLE}" = "true" ]; then
    echo "[pantilt] Starte FLIR-Treiber auf ${PTU_PORT} ..."

    ros2 run flir_ptu_driver ptu_node.py \
        --ros-args \
        -p port:="${PTU_PORT}" \
        -p baud:="${PTU_BAUD}" \
        -p publishing_rate:="${PTU_PUBLISHING_RATE}" &

    DRIVER_PID=$!

    sleep 2
    check_process "FLIR-Treiber" "${DRIVER_PID}"

    echo "[pantilt] FLIR-Treiber gestartet, PID ${DRIVER_PID}."
else
    echo "[pantilt] FLIR-Treiber ist deaktiviert."
fi

echo "[pantilt] Starte aim_and_fire mit ${PANTILT_LAUNCH_FILE} ..."

ros2 launch aim_and_fire "${PANTILT_LAUNCH_FILE}" &
APP_PID=$!

sleep 2
check_process "aim_and_fire" "${APP_PID}"

echo "[pantilt] aim_and_fire gestartet, PID ${APP_PID}."

if [ "${PTU_REFERENCE_ENABLE}" = "true" ]; then
    echo "[pantilt] Starte PTU-Referenz-Service ..."

    ros2 run aim_and_fire ptu_reference \
        --ros-args \
        -p port:="${PTU_PORT}" &

    REFERENCE_PID=$!

    sleep 1
    check_process "PTU-Referenz-Service" "${REFERENCE_PID}"

    echo "[pantilt] PTU-Referenz-Service gestartet, PID ${REFERENCE_PID}."
else
    echo "[pantilt] PTU-Referenz-Service ist deaktiviert."
fi

echo "[pantilt] Alle aktivierten Prozesse laufen."

set +e
wait -n
EXIT_CODE=$?
set -e

echo "[pantilt] Ein Prozess wurde mit Code ${EXIT_CODE} beendet."

exit "${EXIT_CODE}"
```
