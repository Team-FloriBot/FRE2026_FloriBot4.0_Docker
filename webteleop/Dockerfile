FROM ros:jazzy

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    python3-colcon-common-extensions \
    python3-pip \
    git \
    ros-jazzy-rmw-cyclonedds-cpp \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /ws

COPY repos/Webteleop_ROS2_Jazzy_V1/ src/

RUN python3 -m pip install --no-cache-dir --break-system-packages fastapi uvicorn

RUN . /opt/ros/jazzy/setup.sh && \
    colcon build

COPY webteleop/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["ros2", "run", "web_teleop", "web_teleop_server"]
