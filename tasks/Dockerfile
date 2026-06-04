FROM ros:jazzy

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

ARG FRE2026_TASKS_REPO=https://github.com/Team-FloriBot/FRE2026_Tasks.git
ARG FRE2026_TASKS_REF=main

ARG FRE_DETECTION_REPO=https://github.com/Team-FloriBot/FRE_object_detection.git
ARG FRE_DETECTION_REF=docker_ros2_client

ARG CACHEBUST=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    cmake \
    g++ \
    ca-certificates \
    doxygen \
    lcov \
    python3-colcon-common-extensions \
    python3-numpy \
    python3-pip \
    python3-rosdep \
    python3-dev \
    python3-matplotlib \
    python3-tk \
    swig \
    libgl1 \
    libusb-1.0-0 \
    libsm6 \
    libxext6 \
    libeigen3-dev \
    libgdal-dev \
    gdal-bin \
    libgeos-dev \
    libtbb-dev \
    libtinyxml2-dev \
    nlohmann-json3-dev \
    espeak-ng \
    alsa-utils \
    ros-jazzy-rclpy \
    ros-jazzy-geometry-msgs \
    ros-jazzy-nav-msgs \
    ros-jazzy-sensor-msgs \
    ros-jazzy-std-msgs \
    ros-jazzy-std-srvs \
    ros-jazzy-visualization-msgs \
    ros-jazzy-tf2-ros \
    ros-jazzy-tf-transformations \
    ros-jazzy-tf2-geometry-msgs \
    ros-jazzy-tf2-sensor-msgs \
    ros-jazzy-launch \
    ros-jazzy-launch-ros \
    ros-jazzy-rmw-cyclonedds-cpp \
    ros-jazzy-rosidl-default-generators \
    ros-jazzy-rosidl-default-runtime \
    ros-jazzy-cv-bridge \
    ros-jazzy-vision-opencv \
    && rm -rf /var/lib/apt/lists/*

# Fields2Cover wird von task4.coverage_planner importiert.
RUN git clone https://github.com/Fields2Cover/Fields2Cover.git /tmp/Fields2Cover && \
    cd /tmp/Fields2Cover && \
    mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_PYTHON=ON .. && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    rm -rf /tmp/Fields2Cover

WORKDIR /ws
RUN mkdir -p /ws/src

RUN echo "Cache bust: ${CACHEBUST}" && \
    git clone \
      --depth 1 \
      --filter=blob:none \
      --sparse \
      --branch ${FRE2026_TASKS_REF} \
      ${FRE2026_TASKS_REPO} \
      /ws/src/FRE2026_Tasks && \
    cd /ws/src/FRE2026_Tasks && \
    git sparse-checkout set \
      src/maize_navigation \
      src/maize_navigation_interfaces \
      src/fre2026_detection_client \
      src/fre2026_detection_interfaces \
      src/fre2026_tasks_interfaces \
      src/fre2026_audio_feedback \
      src/task4 \
      src/path_tracking_controller

RUN git clone \
      --depth 1 \
      --branch ${FRE_DETECTION_REF} \
      ${FRE_DETECTION_REPO} \
      /ws/src/FRE_object_detection

RUN rosdep init 2>/dev/null || true && \
    rosdep update && \
    apt-get update && \
    source /opt/ros/jazzy/setup.bash && \
    rosdep install \
      --from-paths /ws/src \
      --ignore-src \
      -r \
      -y \
      --skip-keys="laser_scan_merger slam_toolbox" && \
    rm -rf /var/lib/apt/lists/*

RUN source /opt/ros/jazzy/setup.bash && \
    colcon build \
      --symlink-install \
      --packages-select \
        fre2026_detection_interfaces \
        fre2026_tasks_interfaces \
        maize_navigation_interfaces \
        fre2026_detection_client \
        maize_navigation \
        fre2026_audio_feedback \
        task4 \
        path_tracking_controller \
        ros2_detection_interfaces \
        ros2_detection_client

ENV ROS_DOMAIN_ID=0
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

RUN echo "source /opt/ros/jazzy/setup.bash" >> /etc/bash.bashrc && \
    echo "if [ -f /ws/install/setup.bash ]; then source /ws/install/setup.bash; fi" >> /etc/bash.bashrc

COPY tasks/entrypoint.sh /entrypoint.sh
COPY tasks/start_tasks.sh /start_tasks.sh

RUN chmod +x /entrypoint.sh /start_tasks.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/start_tasks.sh"]
