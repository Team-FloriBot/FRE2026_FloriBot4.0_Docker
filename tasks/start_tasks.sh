#!/bin/bash
set -e

source /opt/ros/jazzy/setup.bash

if [ -f /ws/install/setup.bash ]; then
    source /ws/install/setup.bash
fi

echo "Starte Maize Navigation..."
exec ros2 launch maize_navigation maize_navigation.launch.py

echo "Starte Task 4 (Marker Detection, Global Marker Mapping, Coverage Planner)..."
exec ros2 launch task4 task4.launch.py