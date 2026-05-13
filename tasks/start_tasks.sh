#!/bin/bash
set -e

source /opt/ros/jazzy/setup.bash
if [ -f /ws/install/setup.bash ]; then 
    source /ws/install/setup.bash
fi

echo "Starte Laser Scan Merger..."
ros2 launch laser_scan_merger start.launch.py robotname:=floribot_config &

echo "Starte SLAM Toolbox..."
ros2 launch slam_toolbox online_sync_launch.py &

#echo "Starte Maize Navigaion..."
#ros2 launch maize_navigation maize_navigation.launch.py &

wait