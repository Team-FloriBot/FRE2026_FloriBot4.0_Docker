FROM ros:jazzy

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

ARG VIRTUAL_MAIZE_FIELD_REPO=https://github.com/FieldRobotEvent/virtual_maize_field.git
ARG VIRTUAL_MAIZE_FIELD_REF=ros2-gz

ARG FLORIBOT_BASE_REPO=https://github.com/Team-FloriBot/FloriBot4.0_ROS2_Jazzy_Base.git
ARG FLORIBOT_BASE_REF=main

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i 's|http://archive.ubuntu.com/ubuntu|https://archive.ubuntu.com/ubuntu|g' /etc/apt/sources.list.d/ubuntu.sources && \
    sed -i 's|http://security.ubuntu.com/ubuntu|https://security.ubuntu.com/ubuntu|g' /etc/apt/sources.list.d/ubuntu.sources

RUN apt-get update && apt-get install -y \
    git \
    python3-colcon-common-extensions \
    python3-pip \
    python3-rosdep \
    python3-vcstool \
    python3-rospkg \
    python3-jinja2 \
    python3-opencv \
    python3-matplotlib \
    python3-shapely \
    python3-packaging \
    python3-yaml \
    ros-jazzy-xacro \
    ros-jazzy-robot-state-publisher \
    ros-jazzy-joint-state-publisher \
    ros-jazzy-ros-gz \
    ros-jazzy-ros-gz-sim \
    ros-jazzy-ros-gz-bridge \
    ros-jazzy-ros-gz-interfaces \
    ros-jazzy-rmw-cyclonedds-cpp \
    && rm -rf /var/lib/apt/lists/*

ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

WORKDIR /ws/src

RUN git clone --branch ${VIRTUAL_MAIZE_FIELD_REF} --depth 1 ${VIRTUAL_MAIZE_FIELD_REPO} /ws/src/virtual_maize_field

COPY gazebo/ros2_ws/src/floribot_gz_description /ws/src/floribot_gz_description
COPY gazebo/ros2_ws/src/floribot_gz_bringup /ws/src/floribot_gz_bringup
COPY gazebo/ros2_ws/src/sim_backend /ws/src/sim_backend

RUN git clone --branch ${FLORIBOT_BASE_REF} --depth 1 ${FLORIBOT_BASE_REPO} /tmp/floribot_base_repo && \
    cp -r /tmp/floribot_base_repo/src/base /ws/src/ && \
    cp -r /tmp/floribot_base_repo/src/plc_connection /ws/src/ && \
    rm -rf /tmp/floribot_base_repo

WORKDIR /ws

RUN rosdep init 2>/dev/null || true
RUN rosdep update || true

RUN apt-get update && \
    source /opt/ros/jazzy/setup.bash && \
    rosdep install --from-paths /ws/src --ignore-src -r -y && \
    rm -rf /var/lib/apt/lists/*

RUN source /opt/ros/jazzy/setup.bash && \
    colcon build

RUN echo "source /opt/ros/jazzy/setup.bash" >> /root/.bashrc && \
    echo "if [ -f /ws/install/setup.bash ]; then source /ws/install/setup.bash; fi" >> /root/.bashrc

COPY gazebo/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["ros2", "launch", "floribot_gz_bringup", "maize_world_with_floribot.launch.py"]
