FROM ros:jazzy

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

ARG ROBOSENSE_REPO=https://github.com/Team-FloriBot/FRE_RoboSenseAIRY.git
ARG ROBOSENSE_REF=main

RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    cmake \
    python3-colcon-common-extensions \
    python3-rosdep \
    libpcap-dev \
    libyaml-cpp-dev \
    libpcl-dev \
    ros-jazzy-rmw-cyclonedds-cpp \
    ros-jazzy-pcl-conversions \
    ros-jazzy-tf2 \
    ros-jazzy-tf2-ros \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /ws/src

RUN git clone --branch ${ROBOSENSE_REF} --depth 1 \
    ${ROBOSENSE_REPO} FRE_RoboSenseAIRY

WORKDIR /ws

RUN rosdep init 2>/dev/null || true && \
    rosdep update && \
    apt-get update && \
    source /opt/ros/jazzy/setup.bash && \
    rosdep install \
      --from-paths /ws/src/FRE_RoboSenseAIRY \
      --ignore-src \
      --rosdistro jazzy \
      -r -y && \
    rm -rf /var/lib/apt/lists/*

RUN source /opt/ros/jazzy/setup.bash && \
    colcon build \
      --packages-select \
        rslidar_msg \
        rslidar_sdk \
        ground_segmentation \
      --symlink-install \
      --cmake-args -DCMAKE_BUILD_TYPE=Release

COPY robosense/config/rslidar_config.yaml /ws/config/rslidar_config.yaml
COPY robosense/config/ground_segmentation.yaml /ws/config/ground_segmentation.yaml
COPY robosense/start_robosense.sh /start_robosense.sh

RUN chmod +x /start_robosense.sh

CMD ["/start_robosense.sh"]
