FROM ros:jazzy

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

ARG FLORIBOT_BASE_REPO=https://github.com/Team-FloriBot/FloriBot4.0-ROS2_old.git
ARG FLORIBOT_BASE_REF=main

RUN apt-get update && apt-get install -y \
    git \
    python3-colcon-common-extensions \
    python3-pip \
    python3-rosdep \
    python3-vcstool \
    ros-jazzy-desktop \
    ros-jazzy-ros-gz \
    ros-jazzy-ros-gz-sim \
    ros-jazzy-ros-gz-bridge \
    ros-jazzy-controller-manager \
    ros-jazzy-diff-drive-controller \
    ros-jazzy-position-controllers \
    ros-jazzy-joint-state-broadcaster \
    ros-jazzy-robot-state-publisher \
    ros-jazzy-joint-state-publisher \
    ros-jazzy-xacro \
    ros-jazzy-rqt-robot-steering \
    ros-jazzy-rmw-fastrtps-cpp \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

RUN git clone --branch ${FLORIBOT_BASE_REF} --depth 1 ${FLORIBOT_BASE_REPO} floribot_base

WORKDIR /ws

RUN mkdir -p /ws/src && \
    cp -r /tmp/floribot_base/ros2_ws/src/floribot_simulation /ws/src/ && \
    cp -r /tmp/floribot_base/ros2_ws/src/base2gazebo /ws/src/

RUN rosdep init 2>/dev/null || true && rosdep update || true

RUN source /opt/ros/jazzy/setup.bash && \
    rosdep install -i --from-paths /ws/src --rosdistro jazzy --ignore-src -r -y || true

RUN source /opt/ros/jazzy/setup.bash && \
    cd /ws && \
    colcon build

COPY gazebo/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
