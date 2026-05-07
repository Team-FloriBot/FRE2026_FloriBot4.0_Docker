FROM ros:humble

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DOMAIN_ID=0
ENV RMW_IMPLEMENTATION=rmw_fastrtps_cpp
ENV ULTRALYTICS_CONFIG_DIR=/tmp

WORKDIR /ws

ARG OBJECT_DETECTION_REPO=https://github.com/Team-FloriBot/FRE_object_detection.git
ARG OBJECT_DETECTION_BRANCH=main

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    python3-pip \
    python3-rosdep \
    python3-colcon-common-extensions \
    libgl1 \
    libglib2.0-0 \
    libusb-1.0-0 \
    libsm6 \
    libxext6 \
    ros-humble-cv-bridge \
    ros-humble-vision-opencv \
    ros-humble-realsense2-camera-msgs \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel

RUN python3 -m pip install --no-cache-dir "numpy<2.0"

RUN python3 -m pip install --no-cache-dir \
    torch \
    opencv-python \
    scikit-learn \
    pyrealsense2 \
    pyyaml \
    ultralytics

RUN mkdir -p /ws/src /ws/model

RUN git clone --branch ${OBJECT_DETECTION_BRANCH} ${OBJECT_DETECTION_REPO} /tmp/FRE_object_detection && \
    ROS2_DETECTION_DIR=$(find /tmp/FRE_object_detection -type d -name ros2_detection | head -n 1) && \
    ROS2_INTERFACES_DIR=$(find /tmp/FRE_object_detection -type d -name ros2_detection_interfaces | head -n 1) && \
    ROS2_CLIENT_DIR=$(find /tmp/FRE_object_detection -type d -name ros2_detection_client | head -n 1) && \
    if [ -z "$ROS2_DETECTION_DIR" ]; then echo "ERROR: ros2_detection package not found"; find /tmp/FRE_object_detection -maxdepth 4 -type d; exit 1; fi && \
    if [ -z "$ROS2_INTERFACES_DIR" ]; then echo "ERROR: ros2_detection_interfaces package not found"; find /tmp/FRE_object_detection -maxdepth 4 -type d; exit 1; fi && \
    if [ -z "$ROS2_CLIENT_DIR" ]; then echo "ERROR: ros2_detection_client package not found"; find /tmp/FRE_object_detection -maxdepth 4 -type d; exit 1; fi && \
    cp -r "$ROS2_DETECTION_DIR" /ws/src/ && \
    cp -r "$ROS2_INTERFACES_DIR" /ws/src/ && \
    cp -r "$ROS2_CLIENT_DIR" /ws/src/ && \
    MODEL_DIR=$(find /tmp/FRE_object_detection -type d -name model | head -n 1) && \
    if [ -n "$MODEL_DIR" ]; then cp -r "$MODEL_DIR"/* /ws/model/ || true; fi && \
    rm -rf /tmp/FRE_object_detection

RUN source /opt/ros/humble/setup.bash && \
    rosdep update || true && \
    rosdep install --from-paths /ws/src --ignore-src -r -y || true && \
    colcon build --symlink-install

RUN echo "source /opt/ros/humble/setup.bash" >> /root/.bashrc && \
    echo "source /ws/install/setup.bash" >> /root/.bashrc

CMD ["/bin/bash"]
