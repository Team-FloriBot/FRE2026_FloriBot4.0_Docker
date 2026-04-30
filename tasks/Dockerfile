FROM ros:jazzy

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git \
    python3-numpy \
    python3-pip \
    build-essential \
    python3-colcon-common-extensions \
    # 2. ROS 2 Kern-Komponenten
    ros-jazzy-rclpy \
    ros-jazzy-geometry-msgs \
    ros-jazzy-sensor-msgs \
    ros-jazzy-sensor-msgs-py \
    # 3. Transformationen & Geometrie (Wichtig für Punktwolken)
    ros-jazzy-laser-geometry \
    ros-jazzy-tf2-ros \
    ros-jazzy-tf2-sensor-msgs \
    ros-jazzy-tf2-geometry-msgs \
    # 4. Utilities
    ros-jazzy-message-filters \
    ros-jazzy-launch-ros \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /ws

RUN mkdir -p /ws/src && \
    git clone https://github.com/Team-FloriBot/FRE2026_Tasks.git /ws/src/FRE2026_Tasks

RUN . /opt/ros/jazzy/setup.sh && \
    colcon build

RUN echo "source /opt/ros/jazzy/setup.bash" >> /etc/bash.bashrc && \
    echo "if [ -f /ws/install/setup.bash ]; then source /ws/install/setup.bash; fi" >> /etc/bash.bashrc

COPY tasks/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["ros2", "launch", "maize_navigation", "maize_navigation.launch.py"]
