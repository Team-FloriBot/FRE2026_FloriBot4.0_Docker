FROM ros:jazzy

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

ARG ROBOSENSE_REPO=https://github.com/Team-FloriBot/FRE_RoboSenseAIRY.git
ARG ROBOSENSE_REF=parameter_test_feld

ARG ROBOSENSE_REPO_TORSTEM=https://github.com/norikaschneider/Robosense_Torsten.git
ARG ROBOSENSE_TORSTEN_REF=main

RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    cmake \
    pkg-config \
    python3-colcon-common-extensions \
    python3-rosdep \
    libpcap-dev \
    libyaml-cpp-dev \
    libpcl-dev \
    ros-jazzy-rclcpp \
    ros-jazzy-std-msgs \
    ros-jazzy-sensor-msgs \
    ros-jazzy-pcl-conversions \
    ros-jazzy-tf2 \
    ros-jazzy-tf2-ros \
    ros-jazzy-rmw-cyclonedds-cpp \
    && rm -rf /var/lib/apt/lists/*

RUN echo "source /opt/ros/jazzy/setup.bash" >> /root/.bashrc && \
    echo "if [ -f /ws/install/setup.bash ]; then source /ws/install/setup.bash; fi" >> /root/.bashrc

WORKDIR /ws/src

RUN git clone --branch "${ROBOSENSE_REF}" --depth 1 \
    "${ROBOSENSE_REPO}" FRE_RoboSenseAIRY

RUN git clone --branch "${ROBOSENSE_TORSTEN_REF}" --depth 1 \
    "${ROBOSENSE_REPO_TORSTEM}" Robosense_Torsten

WORKDIR /ws

RUN rosdep init 2>/dev/null || true && \
    rosdep update || true

RUN apt-get update && \
    source /opt/ros/jazzy/setup.bash && \
    rosdep install -i \
      --from-paths \
        /ws/src/FRE_RoboSenseAIRY/rslidar_msg \
        /ws/src/FRE_RoboSenseAIRY/rslidar_sdk \
        /ws/src/FRE_RoboSenseAIRY/ground_segmentation \
      --rosdistro jazzy \
      -r -y && \
    rm -rf /var/lib/apt/lists/*

RUN source /opt/ros/jazzy/setup.bash && \
    colcon build \
      --packages-select \
        rslidar_msg \
        rslidar_sdk \
        ground_segmentation \
        pointcloud_to_laserscan-rolling \
      --symlink-install \
      --cmake-args \
        -DCMAKE_BUILD_TYPE=Release

COPY robosense/entrypoint.sh /entrypoint.sh
COPY robosense/start_robosense.sh /start_robosense.sh

RUN chmod +x /entrypoint.sh /start_robosense.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/start_robosense.sh"]
