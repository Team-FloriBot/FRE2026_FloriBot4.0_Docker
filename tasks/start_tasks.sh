#!/bin/bash
set -e

source /opt/ros/jazzy/setup.bash
if [ -f /ws/install/setup.bash ]; then 
    source /ws/install/setup.bash
fi

# Starte beide Launch-Befehle
ros2 launch maize_navigation maize_navigation.launch.py &
ros2 launch laser_scan_merger start.launch.py robotname:=floribot_config &
ros2 launch slam_toolbox online_sync_launch.py &

wait