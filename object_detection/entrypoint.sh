#!/bin/bash
set -e

# The dustynv Jetson ROS image provides ROS Humble as a source-built install
# overlay under /opt/ros/humble/install rather than /opt/ros/humble.
if [ -f /opt/ros/humble/install/setup.bash ]; then
    source /opt/ros/humble/install/setup.bash
elif [ -f /opt/ros/humble/setup.bash ]; then
    source /opt/ros/humble/setup.bash
else
    echo "ERROR: ROS Humble setup.bash was not found." >&2
    echo "Checked:" >&2
    echo "  /opt/ros/humble/install/setup.bash" >&2
    echo "  /opt/ros/humble/setup.bash" >&2
    exit 1
fi

# Source the packages built in this container, including CycloneDDS,
# rmw_cyclonedds_cpp, message definitions and ros2_detection.
if [ -f /ws/install/setup.bash ]; then
    source /ws/install/setup.bash
else
    echo "ERROR: Workspace overlay /ws/install/setup.bash was not found." >&2
    exit 1
fi

exec "$@"
