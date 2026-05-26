FROM ros:jazzy

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

# --- Repositories & Branches ---
ARG FRE2026_TASKS_REPO=https://github.com/Team-FloriBot/FRE2026_Tasks.git
ARG FRE2026_TASKS_REF=main

ARG FRE_DETECTION_REPO=https://github.com/Team-FloriBot/FRE_object_detection.git
ARG FRE_DETECTION_REF=docker_ros2_client

ARG CACHEBUST=1

# --- System- & ROS-Abhängigkeiten installieren ---
RUN apt-get update && apt-get install -y \
    git \
    python3-colcon-common-extensions \
    python3-numpy \
    python3-pip \
    python3-rosdep \
    # Bibliotheken aus dem 2. Dockerfile (OpenCV / System)
    libgl1 \
    libusb-1.0-0 \
    libsm6 \
    libxext6 \
    # ROS-Pakete aus dem 1. Dockerfile
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
    # ROS-Pakete aus dem 2. Dockerfile
    ros-jazzy-cv-bridge \
    ros-jazzy-vision-opencv \
    && rm -rf /var/lib/apt/lists/*

# --- Workspace einrichten & Repositories klonen ---
WORKDIR /ws
RUN mkdir -p /ws/src

# 1. FRE2026_Tasks (Sparse Checkout für maize_navigation)
RUN git clone \
      --depth 1 \
      --filter=blob:none \
      --sparse \
      --branch ${FRE2026_TASKS_REF} \
      ${FRE2026_TASKS_REPO} \
      /ws/src/FRE2026_Tasks && \
    cd /ws/src/FRE2026_Tasks && \
    git sparse-checkout set src/maize_navigation

# 2. FRE_object_detection (Komplettes Repo klonen)
RUN git clone \
      --depth 1 \
      --branch ${FRE_DETECTION_REF} \
      ${FRE_DETECTION_REPO} \
      /ws/src/FRE_object_detection

# --- Rosdep Installation ---
RUN rosdep init 2>/dev/null || true && \
    rosdep update && \
    apt-get update && \
    source /opt/ros/jazzy/setup.bash && \
    rosdep install --from-paths /ws/src --ignore-src -r -y \
      --skip-keys="laser_scan_merger slam_toolbox" && \
    rm -rf /var/lib/apt/lists/*

# --- Workspace bauen ---
# Baut maize_navigation sowie die erkannten Pakete aus dem Detection-Repo
RUN source /opt/ros/jazzy/setup.bash && \
    colcon build --symlink-install --packages-select maize_navigation ros2_detection_interfaces ros2_detection_client

# --- Umgebungsvariablen & Sourcing ---
ENV ROS_DOMAIN_ID=0
# Hinweis: Im 2. Dockerfile stand fastrtps, das 1. Dockerfile installierte cyclonedds. 
# Ich habe es hier auf CycloneDDS belassen, da es oben via apt installiert wird. Bei Bedarf anpassen!
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

RUN echo "source /opt/ros/jazzy/setup.bash" >> /etc/bash.bashrc && \
    echo "if [ -f /ws/install/setup.bash ]; then source /ws/install/setup.bash; fi" >> /etc/bash.bashrc

# --- Entrypoint & Startup ---
COPY tasks/entrypoint.sh /entrypoint.sh
COPY tasks/start_tasks.sh /start_tasks.sh
RUN chmod +x /entrypoint.sh /start_tasks.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/start_tasks.sh"]
