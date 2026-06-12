#!/bin/bash
set -e

source /opt/ros/jazzy/setup.bash

if [ -f /ws/install/setup.bash ]; then
    source /ws/install/setup.bash
fi

cleanup() {
    echo "Beende Tasks-Nodes..."

    for pid in \
        "${AUDIO_PID:-}" \
        "${NAVIGATION_PID:-}" \
        "${TASK4_PID:-}" \
        "${PATH_TRACKING_PID:-}"; do
        if [ -n "$pid" ]; then
            kill "$pid" 2>/dev/null || true
        fi
    done

    wait 2>/dev/null || true
}

trap cleanup SIGINT SIGTERM EXIT

echo "Starte Audio Feedback..."
ros2 launch fre2026_audio_feedback audio_feedback.launch.py &
AUDIO_PID=$!

echo "Starte Maize Navigation..."
ros2 launch maize_navigation maize_navigation.launch.py &
NAVIGATION_PID=$!

#echo "Starte Task 4 Coverage Planner..."
#ros2 launch task4 task4.launch.py &
#TASK4_PID=$!

#echo "Starte Path Tracking Controller..."
#ros2 launch path_tracking_controller path_tracking_controller.launch.py &
#PATH_TRACKING_PID=$!

wait -n \
    "$AUDIO_PID" \
    "$NAVIGATION_PID" #\
    #"$TASK4_PID" \
    #"$PATH_TRACKING_PID"
