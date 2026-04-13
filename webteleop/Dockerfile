FROM ros:jazzy

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

ARG WEBTELEOP_REPO=https://github.com/Team-FloriBot/Webteleop_ROS2_Jazzy_V1.git
ARG WEBTELEOP_REF=main

RUN apt-get update && apt-get install -y \
    git \
    python3-colcon-common-extensions \
    python3-pip \
    ros-jazzy-rmw-fastrtps-cpp \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /ws/src
RUN git clone --branch ${WEBTELEOP_REF} --depth 1 ${WEBTELEOP_REPO} webteleop

WORKDIR /ws
RUN python3 -m pip install --no-cache-dir --break-system-packages fastapi uvicorn

RUN source /opt/ros/jazzy/setup.bash && \
    colcon build

COPY webteleop/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["ros2", "run", "web_teleop", "web_teleop_server"]
