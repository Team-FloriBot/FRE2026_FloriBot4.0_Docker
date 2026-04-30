FROM osrf/ros:jazzy-desktop

ENV DEBIAN_FRONTEND=noninteractive
SHELL ["/bin/bash", "-c"]

RUN apt-get update && apt-get install -y \
    python3-colcon-common-extensions \
    python3-rosdep \
    git \
    build-essential \
    cmake \
    pkg-config \
    libfltk-dev \
    libpng-dev \
    libjpeg-dev \
    libtool \
    libtool-bin \
    libgl1-mesa-dev \
    libglu1-mesa-dev \
    ros-jazzy-ackermann-msgs \
    ros-jazzy-rmw-fastrtps-cpp \
    ros-jazzy-topic-tools \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /ws/src

RUN git clone --depth 1 --branch ros2 https://github.com/tuw-robotics/Stage.git && \
    git clone --depth 1 --branch jazzy https://github.com/tuw-robotics/stage_ros2.git

COPY stage/maize_world/ /ws/src/stage_ros2/world/
COPY stage/rviz/ /ws/src/stage_rviz/

WORKDIR /ws

RUN rosdep init || true
RUN rosdep update || true

RUN apt-get update && rosdep install --from-paths /ws/src --ignore-src -r -y \
    --skip-keys="stage ament_cmake_clang_format ament_cmake_pycodestyle" && \
    rm -rf /var/lib/apt/lists/*

RUN source /opt/ros/jazzy/setup.bash && \
    colcon build --symlink-install

RUN echo "source /opt/ros/jazzy/setup.bash" >> /root/.bashrc && \
    echo "if [ -f /ws/install/setup.bash ]; then source /ws/install/setup.bash; fi" >> /root/.bashrc

COPY stage/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash", "-lc", "\
source /opt/ros/jazzy/setup.bash && \
source /ws/install/setup.bash && \
ros2 launch stage_ros2 stage.launch.py world:=maize_field enforce_prefixes:=false one_tf_tree:=false frame_id_base_link:=base_link & \
sleep 5 && \
ros2 run topic_tools relay /base_scan1 /sensors/scan_front & \
ros2 run topic_tools relay /base_scan2 /sensors/scan_rear & \
exec rviz2 -d /ws/src/stage_rviz/floribot_stage.rviz"]
