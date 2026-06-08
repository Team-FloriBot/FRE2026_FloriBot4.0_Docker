FROM ros:jazzy

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

ARG SICK_SCAN_REPO=https://github.com/SICKAG/sick_scan_xd.git
ARG SICK_SCAN_XD_SHA=2d4796699158762cfee78ece05bf8d7c2ceb68d0
ARG REALSENSE_ROS_REPO=https://github.com/realsenseai/realsense-ros.git
ARG REALSENSE_ROS_SHA=6d87b071dcfef15f2a0407e1e78945256add70d0
ARG LIBREALSENSE_REPO=https://github.com/IntelRealSense/librealsense.git
ARG LIBREALSENSE_REF=v2.57.7
ARG XSENS_MTI_ROS2_REPO=https://github.com/xsenssupport/Xsens_MTi_ROS_Driver_and_Ntrip_Client.git
ARG XSENS_MTI_ROS2_SHA=d6b87ecf63297b814a4084b95a7b5daf0713be62

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
    ros-jazzy-nmea-msgs \
    ros-jazzy-geometry-msgs \
    ros-jazzy-diagnostic-updater \
    ros-jazzy-tf2 \
    ros-jazzy-tf2-ros \
    ros-jazzy-tf2-geometry-msgs \
    ros-jazzy-tf2-sensor-msgs \
    ros-jazzy-laser-geometry \
    ros-jazzy-xacro \
    ros-jazzy-urdf \
    ros-jazzy-rmw-cyclonedds-cpp \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

ENV CMAKE_PREFIX_PATH=/usr/local:${CMAKE_PREFIX_PATH}
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH}
ENV LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}

RUN echo "source /opt/ros/jazzy/setup.bash" >> /root/.bashrc && \
    echo "if [ -f /ws/install/setup.bash ]; then source /ws/install/setup.bash; fi" >> /root/.bashrc

WORKDIR /opt
RUN git clone --branch ${LIBREALSENSE_REF} --depth 1 ${LIBREALSENSE_REPO} librealsense && \
    cd librealsense && \
    mkdir -p build && cd build && \
    cmake .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DBUILD_EXAMPLES=false \
      -DBUILD_GRAPHICAL_EXAMPLES=false \
      -DBUILD_PYTHON_BINDINGS=false \
      -DFORCE_RSUSB_BACKEND=true && \
    make -j"$(nproc)" && \
    make install && \
    ldconfig && \
    cd / && rm -rf /opt/librealsense

WORKDIR /ws/src
RUN git clone --no-checkout ${SICK_SCAN_REPO} sick_scan_xd && \
    cd sick_scan_xd && git fetch --depth 1 origin ${SICK_SCAN_XD_SHA} && git checkout --detach FETCH_HEAD && \
    cd /ws/src && \
    git clone --no-checkout ${REALSENSE_ROS_REPO} realsense-ros && \
    cd realsense-ros && git fetch --depth 1 origin ${REALSENSE_ROS_SHA} && git checkout --detach FETCH_HEAD && \
    cd /ws/src && \
    git clone --no-checkout ${XSENS_MTI_ROS2_REPO} xsens_mti_ros2 && \
    cd xsens_mti_ros2 && git fetch --depth 1 origin ${XSENS_MTI_ROS2_SHA} && git checkout --detach FETCH_HEAD

WORKDIR /ws

RUN rosdep init 2>/dev/null || true
RUN rosdep update || true

RUN apt-get update && \
    source /opt/ros/jazzy/setup.bash && \
    rosdep install -i \
      --from-paths \
        /ws/src/sick_scan_xd \
        /ws/src/realsense-ros \
        /ws/src/xsens_mti_ros2/src/xsens_mti_ros2_driver \
      --rosdistro jazzy \
      --skip-keys "librealsense2" \
      -r -y && \
    rm -rf /var/lib/apt/lists/*

RUN source /opt/ros/jazzy/setup.bash && \
    colcon build \
      --packages-select \
        realsense2_camera \
        realsense2_camera_msgs \
        realsense2_description \
      --symlink-install

ARG CACHEBUST=1

COPY sensors/launch_lasers/ /ws/src/sick_scan_xd/launch/
COPY sensors/launch_imu/ /ws/src/xsens_mti_ros2/src/xsens_mti_ros2_driver/launch/

RUN source /opt/ros/jazzy/setup.bash && \
    colcon build \
      --packages-select \
        sick_scan_xd \
      --symlink-install

RUN source /opt/ros/jazzy/setup.bash && \
    colcon build \
      --packages-select \
        xsens_mti_ros2_driver \
      --symlink-install

COPY sensors/entrypoint.sh /entrypoint.sh
COPY sensors/start_sensors.sh /start_sensors.sh



RUN chmod +x /entrypoint.sh /start_sensors.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/start_sensors.sh"]
