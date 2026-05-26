FROM ros:jazzy

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

ARG WEBTELEOP_REPO=https://github.com/Team-FloriBot/Webteleop_ROS2_Jazzy_V1.git
ARG WEBTELEOP_REF=main

ARG FLORIBOT_BASE_REPO=https://github.com/Team-FloriBot/FloriBot4.0_ROS2_Jazzy_Base.git
ARG FLORIBOT_BASE_REF=main

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    cmake \
    python3-colcon-common-extensions \
    python3-pip \
    ros-jazzy-rmw-cyclonedds-cpp \
    ros-jazzy-rclcpp \
    ros-jazzy-geometry-msgs \
    ros-jazzy-std-msgs \
    ros-jazzy-std-srvs \
    ros-jazzy-rosidl-default-generators \
    ros-jazzy-rosidl-default-runtime \
    ros-jazzy-ament-index-python \
    ros-jazzy-launch \
    ros-jazzy-launch-ros \
    ros-jazzy-ros2launch \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

WORKDIR /ws/src

RUN git clone --branch ${WEBTELEOP_REF} --depth 1 \
    ${WEBTELEOP_REPO} webteleop

RUN git clone --branch ${FLORIBOT_BASE_REF} --depth 1 \
    ${FLORIBOT_BASE_REPO} /tmp/floribot_base && \
    cp -r /tmp/floribot_base/src/cmd_vel_selector /ws/src/ && \
    rm -rf /tmp/floribot_base

WORKDIR /ws

RUN python3 -m pip install --no-cache-dir --break-system-packages \
    fastapi \
    "uvicorn[standard]"

RUN source /opt/ros/jazzy/setup.bash && \
    colcon build --symlink-install \
    --packages-select web_teleop cmd_vel_selector

RUN echo "source /opt/ros/jazzy/setup.bash" >> /root/.bashrc && \
    echo "if [ -f /ws/install/setup.bash ]; then source /ws/install/setup.bash; fi" >> /root/.bashrc

COPY webteleop/entrypoint.sh /entrypoint.sh
COPY webteleop/start_webteleop.sh /start_webteleop.sh

RUN chmod +x /entrypoint.sh /start_webteleop.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/start_webteleop.sh"]
