FROM ros:jazzy

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

ARG FLORIBOT_BASE_REPO=https://github.com/Team-FloriBot/FloriBot4.0_ROS2_Jazzy_Base.git
ARG FLORIBOT_BASE_REF=main
ARG SICK_SCAN_REPO=https://github.com/SICKAG/sick_scan_xd.git
ARG SICK_SCAN_REF=develop
ARG REALSENSE_ROS_REPO=https://github.com/realsenseai/realsense-ros.git
ARG REALSENSE_ROS_REF=ros2-master

RUN apt-get update && apt-get install -y \
    git \
    python3-colcon-common-extensions \
    python3-pip \
    python3-rosdep \
    python3-vcstool \
    ros-jazzy-desktop \
    ros-jazzy-gazebo-ros \
    ros-jazzy-gazebo-ros-pkgs \
    ros-jazzy-gazebo-plugins \
    ros-jazzy-gazebo-ros2-control \
    ros-jazzy-controller-manager \
    ros-jazzy-diff-drive-controller \
    ros-jazzy-position-controllers \
    ros-jazzy-joint-state-broadcaster \
    ros-jazzy-robot-state-publisher \
    ros-jazzy-joint-state-publisher \
    ros-jazzy-xacro \
    ros-jazzy-rqt-robot-steering \
    ros-jazzy-rmw-fastrtps-cpp \
    librealsense2-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

RUN git clone --branch ${FLORIBOT_BASE_REF} --depth 1 ${FLORIBOT_BASE_REPO} floribot_base && \
    git clone --branch ${SICK_SCAN_REF} --depth 1 ${SICK_SCAN_REPO} sick_scan_xd && \
    git clone --branch ${REALSENSE_ROS_REF} --depth 1 ${REALSENSE_ROS_REPO} realsense-ros

WORKDIR /ws
RUN mkdir -p /ws/src && \
    cp -r /tmp/floribot_base/ros2_ws/src/floribot_simulation /ws/src/ && \
    cp -r /tmp/floribot_base/ros2_ws/src/base2gazebo /ws/src/ && \
    cp -r /tmp/sick_scan_xd /ws/src/ && \
    cp -r /tmp/realsense-ros/realsense2_camera /ws/src/ && \
    cp -r /tmp/realsense-ros/realsense2_camera_msgs /ws/src/ && \
    cp -r /tmp/realsense-ros/realsense2_description /ws/src/

RUN rosdep init 2>/dev/null || true && rosdep update || true

RUN source /opt/ros/jazzy/setup.bash && \
    rosdep install -i --from-paths /ws/src --rosdistro jazzy --skip-keys=librealsense2 -r -y || true

RUN source /opt/ros/jazzy/setup.bash && \
    cd /ws && \
    colcon build --packages-select \
      floribot_simulation \
      base2gazebo \
      sick_scan_xd \
      realsense2_description

COPY gazebo/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
