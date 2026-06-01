FROM ros:jazzy-ros-base

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

ARG PANTILT_REPO=https://github.com/Team-FloriBot/PANTILT_ROS2_Jazzy.git
ARG PANTILT_REF=main

ARG FLIR_PTU_DRIVER_REPO=https://github.com/vicoslab/flir_ptu_driver.git
ARG FLIR_PTU_DRIVER_REF=main

ARG CACHEBUST=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    cmake \
    python3-colcon-common-extensions \
    python3-pip \
    python3-rosdep \
    python3-serial \
    libusb-1.0-0 \
    libusb-1.0-0-dev \
    udev \
    ros-jazzy-rclpy \
    ros-jazzy-geometry-msgs \
    ros-jazzy-sensor-msgs \
    ros-jazzy-std-msgs \
    ros-jazzy-launch \
    ros-jazzy-launch-ros \
    ros-jazzy-rmw-cyclonedds-cpp \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /ws

RUN mkdir -p /ws/src

RUN echo "Cache bust: ${CACHEBUST}" && \
    git clone --depth 1 --branch ${PANTILT_REF} \
      ${PANTILT_REPO} \
      /tmp/pantilt_repo && \
    cp -r /tmp/pantilt_repo/src/* /ws/src/ && \
    rm -rf /tmp/pantilt_repo

RUN git clone --depth 1 --branch ${FLIR_PTU_DRIVER_REF} \
      ${FLIR_PTU_DRIVER_REPO} \
      /ws/src/flir_ptu_driver

RUN rosdep init 2>/dev/null || true && \
    rosdep update && \
    apt-get update && \
    source /opt/ros/jazzy/setup.bash && \
    rosdep install \
      --from-paths /ws/src \
      --ignore-src \
      --rosdistro jazzy \
      -r \
      -y && \
    rm -rf /var/lib/apt/lists/*

RUN source /opt/ros/jazzy/setup.bash && \
    colcon build --symlink-install

RUN echo "source /opt/ros/jazzy/setup.bash" >> /etc/bash.bashrc && \
    echo "if [ -f /ws/install/setup.bash ]; then source /ws/install/setup.bash; fi" >> /etc/bash.bashrc

COPY pantilt/entrypoint.sh /entrypoint.sh
COPY pantilt/start_pantilt.sh /start_pantilt.sh

RUN chmod +x /entrypoint.sh /start_pantilt.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/start_pantilt.sh"]
