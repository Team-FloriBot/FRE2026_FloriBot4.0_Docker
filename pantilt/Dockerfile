FROM ros:jazzy-ros-base

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

ARG PANTILT_REPO=https://github.com/Team-FloriBot/PANTILT_ROS2_Jazzy.git
ARG PANTILT_REF=main

ARG FLIR_PTU_DRIVER_REPO=https://github.com/vicoslab/flir_ptu_driver.git
ARG FLIR_PTU_DRIVER_REF=ros2
ARG FLIR_PTU_DRIVER_SHA=69bdda85a52eac2f16a34ec2f390671f0596412f

ARG CACHEBUST=1

# Paketquellen auf HTTPS umstellen und APT robuster gegen instabile Verbindungen machen.
RUN set -eux; \
    for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources; do \
      [ -e "$f" ] || continue; \
      sed -i \
        -e 's|http://ports.ubuntu.com/ubuntu-ports|https://ports.ubuntu.com/ubuntu-ports|g' \
        -e 's|http://archive.ubuntu.com/ubuntu|https://archive.ubuntu.com/ubuntu|g' \
        -e 's|http://security.ubuntu.com/ubuntu|https://security.ubuntu.com/ubuntu|g' \
        "$f"; \
    done && \
    printf '%s\n' \
      'Acquire::ForceIPv4 "true";' \
      'Acquire::Retries "10";' \
      'Acquire::http::Timeout "60";' \
      'Acquire::https::Timeout "60";' \
      'Acquire::Queue-Mode "access";' \
      > /etc/apt/apt.conf.d/80-floribot-network

RUN rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/lib/apt/lists/partial && \
    apt-get -o APT::Update::Error-Mode=any update && \
    apt-get install -y --no-install-recommends \
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
    git clone --depth 1 --branch "${PANTILT_REF}" \
      "${PANTILT_REPO}" \
      /tmp/pantilt_repo && \
    cp -r /tmp/pantilt_repo/src/* /ws/src/ && \
    rm -rf /tmp/pantilt_repo

RUN git clone --depth 1 --branch "${FLIR_PTU_DRIVER_REF}" \
      "${FLIR_PTU_DRIVER_REPO}" \
      /ws/src/flir_ptu_driver && \
    cd /ws/src/flir_ptu_driver && \
    if [ -n "${FLIR_PTU_DRIVER_SHA}" ]; then \
      git fetch --depth 1 origin "${FLIR_PTU_DRIVER_SHA}" && \
      git checkout "${FLIR_PTU_DRIVER_SHA}"; \
    fi && \
    echo "flir_ptu_driver commit:" && \
    git rev-parse HEAD

RUN rosdep init 2>/dev/null || true && \
    rosdep update && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/lib/apt/lists/partial && \
    apt-get -o APT::Update::Error-Mode=any update && \
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
