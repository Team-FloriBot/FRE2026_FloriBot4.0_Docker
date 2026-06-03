#!/bin/bash
set -e

source /opt/ros/jazzy/setup.bash

if [ -f /ws/install/setup.bash ]; then
    source /ws/install/setup.bash
fi

cleanup() {
    echo "Beende Mapping-Nodes..."

    for pid in \
        "${LASER_MUX_PID:-}" \
        "${LASER_MERGER_PID:-}" \
        "${SLAM_PID:-}"; do
        if [ -n "$pid" ]; then
            kill "$pid" 2>/dev/null || true
        fi
    done

    wait 2>/dev/null || true
}

trap cleanup SIGINT SIGTERM EXIT

echo "Starte Laser Mux..."
ros2 launch floribot_scan_mux front_scan_mux.launch.py &
LASER_MUX_PID=$!

echo "Starte Laser Scan Merger..."
ros2 launch laser_scan_merger start.launch.py robotname:=floribot_config &
LASER_MERGER_PID=$!

sleep 3

echo "Starte SLAM Toolbox..."
ros2 launch slam_toolbox online_sync_launch.py \
    slam_params_file:=/ws/src/FRE2026_Tasks/src/slam_toolbox/config/mapper_params_online_sync.yaml &
SLAM_PID=$!

wait -n \
    "$LASER_MUX_PID" \
    "$LASER_MERGER_PID" \
    "$SLAM_PID"
exit_code=$?

exit $exit_code
