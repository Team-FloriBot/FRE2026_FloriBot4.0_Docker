FROM ros:jazzy

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    libpcl-dev \
    ros-jazzy-pcl-ros \
    python3-numpy \
    python3-pip \
    python3-colcon-common-extensions \
    ros-jazzy-rclpy \
    ros-jazzy-geometry-msgs \
    ros-jazzy-sensor-msgs \
    ros-jazzy-sensor-msgs-py \
    ros-jazzy-laser-geometry \
    ros-jazzy-tf2-ros \
    ros-jazzy-tf2-sensor-msgs \
    ros-jazzy-tf2-geometry-msgs \
    ros-jazzy-message-filters \
    ros-jazzy-launch-ros \
    ros-jazzy-slam-toolbox \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /ws

RUN mkdir -p /ws/src && \
    git clone https://github.com/Team-FloriBot/FRE2026_Tasks.git /ws/src/FRE2026_Tasks

RUN apt-get update && \
    rosdep update && \
    rosdep install --from-paths src --ignore-src -y --rosdistro jazzy && \
    rm -rf /var/lib/apt/lists/*

RUN . /opt/ros/jazzy/setup.sh && \
    colcon build

RUN echo "source /opt/ros/jazzy/setup.bash" >> /etc/bash.bashrc && \
    echo "if [ -f /ws/install/setup.bash ]; then source /ws/install/setup.bash; fi" >> /etc/bash.bashrc

COPY tasks/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/start_tasks.sh"]
