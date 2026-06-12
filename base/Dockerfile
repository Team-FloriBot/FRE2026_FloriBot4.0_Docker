FROM ros:jazzy

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

ARG APT_UPDATE_OPTS="-o Acquire::Retries=5 -o Acquire::http::Timeout=30 -o Acquire::https::Timeout=30 -o APT::Update::Error-Mode=any"

ARG FLORIBOT_BASE_REPO=https://github.com/Team-FloriBot/FloriBot4.0_ROS2_Jazzy_Base.git
ARG FLORIBOT_BASE_REF=main

ARG ROBOT_LOCALIZATION_REPO=https://github.com/cra-ros-pkg/robot_localization.git
ARG ROBOT_LOCALIZATION_SHA=3efa714fb9c1ff40966327b7bed7053b2570be4d

RUN [[ "${ROBOT_LOCALIZATION_SHA}" =~ ^[0-9a-f]{40}$ ]] || \
    (echo "ROBOT_LOCALIZATION_SHA must be a 40-character git commit hash" && exit 1)

RUN grep -rl 'http://ports.ubuntu.com\|http://packages.ros.org' \
        /etc/apt/sources.list /etc/apt/sources.list.d 2>/dev/null | \
    xargs -r sed -i \
        -e 's|http://ports.ubuntu.com|https://ports.ubuntu.com|g' \
        -e 's|http://packages.ros.org|https://packages.ros.org|g'

RUN apt-get ${APT_UPDATE_OPTS} update && apt-get install -y \
    git \
    build-essential \
    cmake \
    python3-colcon-common-extensions \
    python3-pip \
    python3-rosdep \
    python3-vcstool \
    python3-numpy \
    libeigen3-dev \
    libboost-system-dev \
    geographiclib-tools \
    libgeographiclib-dev \
    ros-jazzy-rclcpp \
    ros-jazzy-rclpy \
    ros-jazzy-std-msgs \
    ros-jazzy-std-srvs \
    ros-jazzy-geometry-msgs \
    ros-jazzy-nav-msgs \
    ros-jazzy-sensor-msgs \
    ros-jazzy-geographic-msgs \
    ros-jazzy-diagnostic-msgs \
    ros-jazzy-diagnostic-updater \
    ros-jazzy-angles \
    ros-jazzy-tf2 \
    ros-jazzy-tf2-ros \
    ros-jazzy-tf2-eigen \
    ros-jazzy-tf2-geometry-msgs \
    ros-jazzy-tf2-sensor-msgs \
    ros-jazzy-message-filters \
    ros-jazzy-yaml-cpp-vendor \
    ros-jazzy-rosidl-default-generators \
    ros-jazzy-rosidl-default-runtime \
    ros-jazzy-launch \
    ros-jazzy-launch-ros \
    ros-jazzy-rmw-cyclonedds-cpp \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /ws

ARG CACHEBUST=1

# FloriBot-Base-Repository laden
RUN git clone --branch ${FLORIBOT_BASE_REF} --depth 1 \
    ${FLORIBOT_BASE_REPO} /tmp/floribot_base

# Bestehende Base-Pakete übernehmen. EKF-Konfiguration wird per Volume eingebunden.
RUN mkdir -p /ws/src /ws/config/localization
RUN cp -r /tmp/floribot_base/src/base /ws/src/
RUN cp -r /tmp/floribot_base/src/plc_connection /ws/src/
RUN cp -r /tmp/floribot_base/src/robot_description /ws/src/

# robot_localization mit identischem Commit wie im Dev-Container laden
RUN git clone ${ROBOT_LOCALIZATION_REPO} /ws/src/robot_localization && \
    cd /ws/src/robot_localization && \
    git checkout ${ROBOT_LOCALIZATION_SHA}

RUN rm -rf /tmp/floribot_base

RUN rosdep init 2>/dev/null || true
RUN rosdep update || true

RUN apt-get ${APT_UPDATE_OPTS} update && \
    source /opt/ros/jazzy/setup.bash && \
    rosdep install --from-paths /ws/src --ignore-src -r -y && \
    rm -rf /var/lib/apt/lists/*

RUN source /opt/ros/jazzy/setup.bash && \
    cd /ws && \
    colcon build --packages-select \
        base \
        plc_connection \
        robot_description \
        robot_localization

RUN echo "source /opt/ros/jazzy/setup.bash" >> /root/.bashrc && \
    echo "if [ -f /ws/install/setup.bash ]; then source /ws/install/setup.bash; fi" >> /root/.bashrc

COPY base/entrypoint.sh /entrypoint.sh
COPY base/start_base.sh /start_base.sh
RUN chmod +x /entrypoint.sh /start_base.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/start_base.sh"]
