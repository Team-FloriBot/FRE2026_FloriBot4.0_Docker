```dockerfile
FROM ros:jazzy

ENV DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-c"]

ARG UBLOX_REPOSITORY=https://github.com/KumarRobotics/ublox.git
ARG UBLOX_BRANCH=ros2

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        git \
        python3-colcon-common-extensions \
        python3-rosdep \
        udev \
        usbutils \
        ros-jazzy-rmw-cyclonedds-cpp \
        ros-jazzy-robot-localization \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /ws

RUN mkdir -p /ws/src \
    && git clone \
        --depth 1 \
        --branch "${UBLOX_BRANCH}" \
        "${UBLOX_REPOSITORY}" \
        /ws/src/ublox

RUN apt-get update \
    && source /opt/ros/jazzy/setup.bash \
    && rosdep update \
    && rosdep install \
        --from-paths /ws/src \
        --ignore-src \
        --rosdistro jazzy \
        -r \
        -y \
    && rm -rf /var/lib/apt/lists/*

RUN source /opt/ros/jazzy/setup.bash \
    && colcon \
        --log-base /ws/log \
        build \
        --base-paths /ws/src \
        --build-base /ws/build \
        --install-base /ws/install \
        --merge-install \
        --cmake-args \
            -DCMAKE_BUILD_TYPE=Release

COPY gps/zed_f9p_rover.yaml /etc/floribot/gps/zed_f9p_rover.yaml
COPY gps/entrypoint.sh /entrypoint.sh
COPY gps/start_gps.sh /start_gps.sh

RUN chmod +x \
    /entrypoint.sh \
    /start_gps.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/start_gps.sh"]
```
