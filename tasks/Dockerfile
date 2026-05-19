FROM ros:jazzy

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

ARG FRE2026_TASKS_REPO=https://github.com/Team-FloriBot/FRE2026_Tasks.git
ARG FRE2026_TASKS_REF=main
ARG CACHEBUST=1

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
    ros-jazzy-launch \
    ros-jazzy-launch-ros \
    ros-jazzy-rmw-cyclonedds-cpp \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /ws

RUN mkdir -p /ws/src && \
    git clone \
      --depth 1 \
      --filter=blob:none \
      --sparse \
      --branch ${FRE2026_TASKS_REF} \
      ${FRE2026_TASKS_REPO} \
      /ws/src/FRE2026_Tasks && \
    cd /ws/src/FRE2026_Tasks && \
    git sparse-checkout set src/maize_navigation

RUN rosdep init 2>/dev/null || true && \
    rosdep update && \
    apt-get update && \
    source /opt/ros/jazzy/setup.bash && \
    rosdep install --from-paths /ws/src --ignore-src -r -y \
      --skip-keys="laser_scan_merger slam_toolbox" && \
    rm -rf /var/lib/apt/lists/*

RUN source /opt/ros/jazzy/setup.bash && \
    colcon build --packages-select maize_navigation

RUN echo "source /opt/ros/jazzy/setup.bash" >> /etc/bash.bashrc && \
    echo "if [ -f /ws/install/setup.bash ]; then source /ws/install/setup.bash; fi" >> /etc/bash.bashrc

COPY tasks/entrypoint.sh /entrypoint.sh
COPY tasks/start_tasks.sh /start_tasks.sh
RUN chmod +x /entrypoint.sh /start_tasks.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/start_tasks.sh"]
