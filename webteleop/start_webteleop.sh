#!/bin/bash
set -euo pipefail

echo "Starte cmd_vel_selector..."
ros2 launch cmd_vel_selector cmd_vel_selector.launch.py &
selector_pid=$!

echo "Starte Webteleop Server..."
ros2 run web_teleop web_teleop_server &
webteleop_pid=$!

cleanup() {
    echo "Beende Webteleop und cmd_vel_selector..."
    kill "${selector_pid}" "${webteleop_pid}" 2>/dev/null || true
    wait "${selector_pid}" "${webteleop_pid}" 2>/dev/null || true
}

trap cleanup SIGINT SIGTERM EXIT

wait -n "${selector_pid}" "${webteleop_pid}"
exit_code=$?

cleanup
exit "${exit_code}"
