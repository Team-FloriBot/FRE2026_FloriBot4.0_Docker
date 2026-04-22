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
    && rm -rf /var/lib/apt/lists/*

WORKDIR /ws/src

RUN git clone --depth 1 --branch ros2 https://github.com/tuw-robotics/Stage.git && \
    git clone --depth 1 --branch jazzy https://github.com/tuw-robotics/stage_ros2.git

COPY stage/maize_world/ /ws/src/stage_ros2/world/

WORKDIR /ws

RUN rosdep init || true
RUN rosdep update

RUN echo "source /pfad/zu/deinem/workspace/install/setup.bash" >> /root/.bashrc

RUN apt-get update && rosdep install --from-paths /ws/src --ignore-src -r -y \
    --skip-keys="stage ament_cmake_clang_format ament_cmake_pycodestyle"

RUN . /opt/ros/jazzy/setup.sh && \
    colcon build --symlink-install

COPY stage/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["ros2", "launch", "stage_ros2", "demo.launch.py", "world:=maize_field"]
