FROM ros:jazzy

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

ARG SICK_SCAN_REPO=https://github.com/SICKAG/sick_scan_xd.git
ARG SICK_SCAN_REF=develop
ARG REALSENSE_ROS_REPO=https://github.com/realsenseai/realsense-ros.git
ARG REALSENSE_ROS_REF=ros2-master
ARG LIBREALSENSE_REPO=https://github.com/IntelRealSense/librealsense.git
ARG LIBREALSENSE_REF=v2.57.7

RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    cmake \
    pkg-config \
    python3-colcon-common-extensions \
    python3-pip \
    python3-rosdep \
    python3-vcstool \
    python3-numpy \
    usbutils \
    udev \
    libusb-1.0-0-dev \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    libudev-dev \
    libx11-dev \
    libglfw3-dev \
    libopencv-dev \
    ros-jazzy-cv-bridge \
    ros-jazzy-image-transport \
    ros-jazzy-rclcpp \
    ros-jazzy-rclpy \
    ros-jazzy-std-msgs \
    ros-jazzy-sensor-msgs \
    ros-jazzy-sensor-msgs-py \
    ros-jazzy-geometry-msgs \
    ros-jazzy-diagnostic-updater \
    ros-jazzy-tf2 \
    ros-jazzy-tf2-ros \
    ros-jazzy-tf2-geometry-msgs \
    ros-jazzy-tf2-sensor-msgs \
    ros-jazzy-laser-geometry \
    ros-jazzy-xacro \
    ros-jazzy-urdf \
    ros-jazzy-rmw-fastrtps-cpp \
    && rm -rf /var/lib/apt/lists/*

ENV CMAKE_PREFIX_PATH=/usr/local:${CMAKE_PREFIX_PATH}
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH}
ENV LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}

# ROS-Umgebung beim interaktiven Start automatisch laden
RUN echo "source /opt/ros/jazzy/setup.bash" >> /root/.bashrc && \
    echo "if [ -f /ws/install/setup.bash ]; then source /ws/install/setup.bash; fi" >> /root/.bashrc

# librealsense aus Source bauen
WORKDIR /opt
RUN git clone --branch ${LIBREALSENSE_REF} --depth 1 ${LIBREALSENSE_REPO} librealsense && \
    cd librealsense && \
    mkdir build && cd build && \
    cmake .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_EXAMPLES=false \
      -DBUILD_GRAPHICAL_EXAMPLES=false \
      -DBUILD_PYTHON_BINDINGS=false \
      -DFORCE_RSUSB_BACKEND=true && \
    make -j"$(nproc)" && \
    make install && \
    ldconfig

# ROS2-Workspace vorbereiten
WORKDIR /ws/src
RUN git clone --branch ${SICK_SCAN_REF} --depth 1 ${SICK_SCAN_REPO} sick_scan_xd && \
    git clone --branch ${REALSENSE_ROS_REF} --depth 1 ${REALSENSE_ROS_REPO} realsense-ros

WORKDIR /ws

# rosdep initialisieren und Abhängigkeiten auflösen
RUN rosdep init 2>/dev/null || true && \
    rosdep update

RUN source /opt/ros/jazzy/setup.bash && \
    rosdep install -i \
      --from-paths /ws/src \
      --rosdistro jazzy \
      --skip-keys "librealsense2" \
      -r -y

# Sensorpakete bauen
RUN source /opt/ros/jazzy/setup.bash && \
    colcon build \
      --packages-select \
        sick_scan_xd \
        realsense2_camera \
        realsense2_camera_msgs \
        realsense2_description \
      --symlink-install

COPY sensors/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
