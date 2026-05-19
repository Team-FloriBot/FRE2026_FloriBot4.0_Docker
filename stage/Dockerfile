FROM ros:jazzy

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
    ros-jazzy-rmw-cyclonedds-cpp \
    ros-jazzy-topic-tools \
    ros-jazzy-tf2-ros \
    ros-jazzy-tf2-tools \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /ws/src

RUN git clone --depth 1 --branch ros2 https://github.com/tuw-robotics/Stage.git && \
    git clone --depth 1 --branch jazzy https://github.com/tuw-robotics/stage_ros2.git && \
    python3 - <<'PY'
from pathlib import Path

path = Path("/ws/src/stage_ros2/src/ranger.cpp")
text = path.read_text()

old = 'topic_name = vehicle->topic_name_space_ + TOPIC_LASER;\n  frame_id = vehicle->frame_name_space_ + FRAME_LASER;\n  if (add_id_to_topic) {\n    topic_name += std::to_string(id());\n    frame_id += std::to_string(id());\n  }'

new = 'topic_name = vehicle->topic_name_space_ + TOPIC_LASER;\n  if (add_id_to_topic) {\n    topic_name += std::to_string(id());\n  }\n\n  if (id() == 1) {\n    frame_id = "sick_front_link";\n  } else if (id() == 2) {\n    frame_id = "sick_rear_link";\n  } else {\n    frame_id = vehicle->frame_name_space_ + FRAME_LASER;\n    if (add_id_to_topic) {\n      frame_id += std::to_string(id());\n    }\n  }'

if old not in text:
    raise RuntimeError("Patch target not found in ranger.cpp")

text = text.replace(old, new, 1)
path.write_text(text)
PY

COPY stage/maize_world/ /ws/src/stage_ros2/world/

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
stage_pid=$! && \
sleep 5 && \
ros2 run topic_tools relay /base_scan1 /sensors/scan_front & \
relay_front_pid=$! && \
ros2 run topic_tools relay /base_scan2 /sensors/scan_rear & \
relay_rear_pid=$! && \
wait -n $stage_pid $relay_front_pid $relay_rear_pid"]
