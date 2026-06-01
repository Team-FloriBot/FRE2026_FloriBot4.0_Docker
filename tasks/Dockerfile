FROM ros:jazzy

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

ARG FRE2026_TASKS_REPO=https://github.com/Team-FloriBot/FRE2026_Tasks.git
ARG FRE2026_TASKS_REF=task4

RUN apt-get update && apt-get install -y \
    git \
    python3-colcon-common-extensions \
    python3-numpy \
    python3-pip \
    python3-rosdep \
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
    ros-jazzy-cv-bridge \
    ros-jazzy-image-transport \
    ros-jazzy-image-transport-plugins \
    ros-jazzy-nav2-bringup \
    ros-jazzy-nav2-controller \
    ros-jazzy-nav2-planner \
    ros-jazzy-nav2-behavior-tree \
    ros-jazzy-nav2-behaviors \
    swig \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/Fields2Cover/Fields2Cover.git /tmp/Fields2Cover && \
    cd /tmp/Fields2Cover && \
    mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_PYTHON=ON .. && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    rm -rf /tmp/Fields2Cover

WORKDIR /ws

ARG CACHEBUST=1

RUN mkdir -p /ws/src && \
    git clone \
      --depth 1 \
      --filter=blob:none \
      --sparse \
      --branch ${FRE2026_TASKS_REF} \
      ${FRE2026_TASKS_REPO} \
      /tmp/FRE2026_Tasks && \
    cd /tmp/FRE2026_Tasks && \
    git sparse-checkout set src/maize_navigation src/task4 src/path_tracking_controller && \
    # Verschiebe die Pakete direkt nach /ws/src/
    mv src/maize_navigation /ws/src/ && \
    mv src/task4 /ws/src/ && \
    mv src/path_tracking_controller /ws/src/ && \
    # Aufräumen des temporären Git-Verzeichnisses
    rm -rf /tmp/FRE2026_Tasks

RUN rosdep init 2>/dev/null || true && \
    rosdep update && \
    apt-get update && \
    source /opt/ros/jazzy/setup.bash && \
    rosdep install --from-paths /ws/src --ignore-src -r -y \
      --skip-keys="laser_scan_merger slam_toolbox" && \
    rm -rf /var/lib/apt/lists/*

RUN source /opt/ros/jazzy/setup.bash && \
    colcon build --packages-select maize_navigation task4 path_tracking_controller

RUN echo "source /opt/ros/jazzy/setup.bash" >> /etc/bash.bashrc && \
    echo "if [ -f /ws/install/setup.bash ]; then source /ws/install/setup.bash; fi" >> /etc/bash.bashrc

COPY tasks/entrypoint.sh /entrypoint.sh
COPY tasks/start_tasks.sh /start_tasks.sh
RUN chmod +x /entrypoint.sh /start_tasks.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/start_tasks.sh"]
