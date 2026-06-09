#!/bin/bash
set -e

ROS_SETUP="/opt/ros/${ROS_DISTRO:-jazzy}/setup.bash"

if [ -f "${ROS_SETUP}" ]; then
    source "${ROS_SETUP}"
else
    echo "ERROR: ROS setup file was not found: ${ROS_SETUP}" >&2
    exit 1
fi

if [ -f /ws/install/setup.bash ]; then
    source /ws/install/setup.bash
else
    echo "ERROR: Workspace overlay /ws/install/setup.bash was not found." >&2
    exit 1
fi

exec "$@"
