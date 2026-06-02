#!/bin/bash
set -e

source /opt/ros/jazzy/setup.bash

if [ -f /ws/install/setup.bash ]; then
    source /ws/install/setup.bash
fi

cleanup() {
    echo "Beende Tasks-Nodes..."

    if [ -n "${AUDIO_PID:-}" ]; then
        kill "${AUDIO_PID}" 2>/dev/null || true
    fi

    if [ -n "${NAVIGATION_PID:-}" ]; then
        kill "${NAVIGATION_PID}" 2>/dev/null || true
    fi

    wait 2>/dev/null || true
}

trap cleanup SIGINT SIGTERM EXIT

echo "Starte Audio Feedback..."
ros2 launch fre2026_audio_feedback audio_feedback.launch.py &
AUDIO_PID=$!

echo "Starte Maize Navigation..."
ros2 launch maize_navigation maize_navigation.launch.py &
NAVIGATION_PID=$!

wait -n "${AUDIO_PID}" "${NAVIGATION_PID}"
