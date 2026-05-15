#!/bin/bash
set -e

source /opt/ros/jazzy/setup.bash
if [ -f /ws/install/setup.bash ]; then 
    source /ws/install/setup.bash
fi

echo "Starte Robot Description..."
ros2 launch robot_description launch.py &

echo "Starte Base..."
ros2 launch base base_node.launch.py &

echo "Starte PLC Connection ..."
ros2 launch plc_connection plc_connection_launch.py &

wait