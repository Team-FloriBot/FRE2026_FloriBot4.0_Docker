#!/bin/bash

set -euo pipefail


selector_pid=""
webteleop_pid=""
jury_dashboard_pid=""


cleanup() {
    echo "Beende Webteleop, Jury Dashboard und cmd_vel_selector..."

    for pid in \
        "${jury_dashboard_pid}" \
        "${webteleop_pid}" \
        "${selector_pid}"; do

        if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
            kill "${pid}" 2>/dev/null || true
        fi
    done

    for pid in \
        "${jury_dashboard_pid}" \
        "${webteleop_pid}" \
        "${selector_pid}"; do

        if [[ -n "${pid}" ]]; then
            wait "${pid}" 2>/dev/null || true
        fi
    done
}


trap cleanup SIGINT SIGTERM EXIT


echo "Starte cmd_vel_selector..."

ros2 launch \
    cmd_vel_selector \
    cmd_vel_selector.launch.py &

selector_pid=$!


echo "Starte Webteleop Server auf Port 8000..."

ros2 run \
    web_teleop \
    web_teleop_server &

webteleop_pid=$!


echo "Starte Jury Dashboard auf Port 8081..."

ros2 launch \
    jury_dashboard \
    jury_dashboard.launch.py &

jury_dashboard_pid=$!


set +e

wait -n \
    "${selector_pid}" \
    "${webteleop_pid}" \
    "${jury_dashboard_pid}"

exit_code=$?

set -e


echo "Mindestens ein Prozess wurde beendet."

cleanup

exit "${exit_code}"
