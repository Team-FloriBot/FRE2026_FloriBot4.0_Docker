# Object detection for NVIDIA Jetson Xavier / JetPack 5 (L4T R35).
# The sensors container owns the RealSense hardware and publishes RGBD messages.
ARG JETSON_ROS_IMAGE=dustynv/ros:humble-pytorch-l4t-r35.3.1
FROM ${JETSON_ROS_IMAGE}

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=humble
ENV ULTRALYTICS_CONFIG_DIR=/tmp
ENV YOLO_CONFIG_DIR=/tmp
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

WORKDIR /ws

ARG VISION_OPENCV_REPO=https://github.com/ros-perception/vision_opencv.git
ARG VISION_OPENCV_REF=humble

# Only required for the RGBD ROS message definition.
# No RealSense camera driver is built in this container.
ARG REALSENSE_MSGS_REPO=https://github.com/realsenseai/realsense-ros.git
ARG REALSENSE_MSGS_REF=ros2-master

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    cmake \
    python3-pip \
    python3-colcon-common-extensions \
    python3-numpy \
    python3-opencv \
    libopencv-dev \
    libboost-dev \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    && rm -rf /var/lib/apt/lists/*

# CUDA-enabled torch/torchvision are supplied by the Jetson base image.
RUN python3 -m pip install --no-cache-dir \
    "numpy<2.0" \
    pyyaml \
    scikit-learn \
    pillow \
    requests \
    scipy \
    psutil \
    matplotlib \
    polars \
    ultralytics-thop && \
    python3 -m pip install --no-cache-dir --no-deps "ultralytics<8.4"

RUN mkdir -p /ws/src /ws/model && \
    git clone --depth 1 --branch ${VISION_OPENCV_REF} \
        ${VISION_OPENCV_REPO} /ws/src/vision_opencv && \
    git clone --depth 1 --branch ${REALSENSE_MSGS_REF} \
        ${REALSENSE_MSGS_REPO} /tmp/realsense-msgs-source && \
    cp -r /tmp/realsense-msgs-source/realsense2_camera_msgs /ws/src/ && \
    rm -rf /tmp/realsense-msgs-source

# Only the message definition is compiled here. The RealSense camera node and
# librealsense remain exclusively in the sensors container.
COPY object_detection/ros2_ws/src /ws/src
COPY object_detection/model /ws/model

RUN source /opt/ros/humble/install/setup.bash && \
    colcon build --symlink-install --packages-select \
        cv_bridge \
        realsense2_camera_msgs \
        ros2_detection_interfaces \
        ros2_detection

# Same behaviour as the other FloriBot containers:
# ROS and workspace are available in an interactive container shell.
RUN echo 'if [ -f /opt/ros/humble/setup.bash ]; then source /opt/ros/humble/setup.bash; elif [ -f /opt/ros/humble/install/setup.bash ]; then source /opt/ros/humble/install/setup.bash; fi' >> /etc/bash.bashrc && \
    echo 'if [ -f /ws/install/setup.bash ]; then source /ws/install/setup.bash; fi' >> /etc/bash.bashrc

COPY object_detection/entrypoint.sh /entrypoint.sh
COPY object_detection/start_object_detection.sh /start_object_detection.sh

RUN chmod +x /entrypoint.sh /start_object_detection.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/start_object_detection.sh"]
