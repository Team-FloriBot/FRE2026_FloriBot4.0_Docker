FROM ros:jazzy

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

ARG FRE2026_TASKS_REPO=https://github.com/Team-FloriBot/FRE2026_Tasks.git
ARG FRE2026_TASKS_REF=main
ARG CACHEBUST=1

RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    libpcl-dev \
    python3-colcon-common-extensions \
    ros-jazzy-rclpy \
    ros-jazzy-ament-cmake-auto \
    ros-jazzy-rosidl-default-generators \
    ros-jazzy-rosidl-default-runtime \
    ros-jazzy-rclcpp \
    ros-jazzy-rclcpp-components \
    ros-jazzy-message-filters \
    ros-jazzy-sensor-msgs \
    ros-jazzy-geometry-msgs \
    ros-jazzy-nav-msgs \
    ros-jazzy-std-msgs \
    ros-jazzy-tf2 \
    ros-jazzy-tf2-ros \
    ros-jazzy-tf2-sensor-msgs \
    ros-jazzy-laser-geometry \
    ros-jazzy-pcl-conversions \
    ros-jazzy-pcl-ros \
    ros-jazzy-slam-toolbox \
    ros-jazzy-rmw-cyclonedds-cpp \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /ws

RUN echo "Cache bust: ${CACHEBUST}" && \
    mkdir -p /ws/src && \
    git clone \
      --depth 1 \
      --filter=blob:none \
      --sparse \
      --branch ${FRE2026_TASKS_REF} \
      ${FRE2026_TASKS_REPO} \
      /ws/src/FRE2026_Tasks && \
    cd /ws/src/FRE2026_Tasks && \
    git sparse-checkout set \
      src/fre2026_tasks_interfaces \
      src/floribot_scan_mux \
      src/laser_scan_merger \
      src/slam_toolbox

RUN source /opt/ros/jazzy/setup.bash && \
    colcon build \
      --packages-select \
        fre2026_tasks_interfaces \
        floribot_scan_mux \
        laser_scan_merger

RUN echo "source /opt/ros/jazzy/setup.bash" >> /etc/bash.bashrc && \
    echo "if [ -f /ws/install/setup.bash ]; then source /ws/install/setup.bash; fi" >> /etc/bash.bashrc

COPY mapping/entrypoint.sh /entrypoint.sh
COPY mapping/start_mapping.sh /start_mapping.sh
RUN chmod +x /entrypoint.sh /start_mapping.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/start_mapping.sh"]
