#!/bin/bash
set -e

source /opt/ros/jazzy/setup.bash

if [ -f /ws/install/setup.bash ]; then
    source /ws/install/setup.bash
fi

LOCALIZATION_CONFIG=${LOCALIZATION_CONFIG:-/ws/config/localization/local_ekf.yaml}

test -f "${LOCALIZATION_CONFIG}" || {
    echo "ERROR: EKF config not found: ${LOCALIZATION_CONFIG}"
    exit 1
}

echo "Starte Robot Description..."
ros2 launch robot_description launch.py &

echo "Starte Base..."
ros2 launch base base_node.launch.py &

echo "Starte PLC Connection..."
ros2 launch plc_connection plc_connection_launch.py &

echo "Starte robot_localization EKF..."
ros2 run robot_localization ekf_node \
    --ros-args \
    --params-file "${LOCALIZATION_CONFIG}" \
    -p publish_tf:=true &

wait
