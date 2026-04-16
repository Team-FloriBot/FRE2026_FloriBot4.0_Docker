#!/bin/bash
set -e

source /opt/ros/jazzy/setup.bash

if [ -f /ws/install/setup.bash ]; then
  source /ws/install/setup.bash
fi

export GZ_SIM_RESOURCE_PATH=/ws/src/floribot_gz_description:/ws/src/floribot_gz_description/meshes:${GZ_SIM_RESOURCE_PATH}

exec "$@"
