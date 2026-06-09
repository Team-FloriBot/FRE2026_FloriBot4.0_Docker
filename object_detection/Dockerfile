# Object detection container for an x86_64 laptop/desktop with NVIDIA GPU.
# Host requirements: NVIDIA driver and NVIDIA Container Toolkit.
# The RealSense camera remains owned by the sensors container; this container
# consumes the published ROS RGBD messages.

ARG CUDA_IMAGE=nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04
FROM ${CUDA_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    ROS_DISTRO=humble \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    ULTRALYTICS_CONFIG_DIR=/tmp/ultralytics \
    YOLO_CONFIG_DIR=/tmp/ultralytics \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    PIP_DEFAULT_TIMEOUT=600 \
    PIP_RETRIES=10 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /ws

ARG REALSENSE_MSGS_REPO=https://github.com/realsenseai/realsense-ros.git
ARG REALSENSE_MSGS_SHA=6d87b071dcfef15f2a0407e1e78945256add70d0
ARG OBJECT_DETECTION_REPO=https://github.com/Team-FloriBot/FRE_object_detection.git
ARG OBJECT_DETECTION_REF=docker_ros2
ARG PYTORCH_CUDA_INDEX=https://download.pytorch.org/whl/cu124

# ROS 2 Humble and build/runtime dependencies for Ubuntu 22.04 x86_64.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg2 \
        locales \
        software-properties-common; \
    locale-gen en_US.UTF-8; \
    add-apt-repository universe; \
    curl -fsSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
        -o /usr/share/keyrings/ros-archive-keyring.gpg; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo ${UBUNTU_CODENAME}) main" \
        > /etc/apt/sources.list.d/ros2.list; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        git \
        build-essential \
        cmake \
        pkg-config \
        python3 \
        python3-dev \
        python3-pip \
        python3-setuptools \
        python3-colcon-common-extensions \
        python3-rosdep \
        ros-humble-ros-base \
        ros-humble-cv-bridge \
        ros-humble-rmw-cyclonedds-cpp \
        libgl1 \
        libglib2.0-0 \
        libsm6 \
        libxext6; \
    rm -rf /var/lib/apt/lists/*

# CUDA-enabled PyTorch wheels for ordinary NVIDIA GPUs.
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install \
        --index-url "${PYTORCH_CUDA_INDEX}" \
        torch==2.5.1 \
        torchvision==0.20.1 && \
    python3 -m pip install \
        --prefer-binary \
        "numpy<2.0" \
        pyyaml \
        "scikit-learn==1.3.2" \
        pillow \
        requests \
        "scipy==1.10.1" \
        psutil \
        matplotlib \
        polars \
        pyrealsense2==2.57.7.12974 \
        ultralytics-thop && \
    python3 -m pip install \
        --no-deps \
        "ultralytics==8.4.48"

RUN mkdir -p /ws/src /ws/model /tmp/ultralytics

# Build the exact RealSense message definitions used by the sensors container.
RUN set -eux; \
    git clone --no-checkout \
        "${REALSENSE_MSGS_REPO}" \
        /tmp/realsense-ros; \
    cd /tmp/realsense-ros; \
    git fetch --depth 1 origin "${REALSENSE_MSGS_SHA}"; \
    git checkout --detach FETCH_HEAD; \
    test "$(git rev-parse HEAD)" = "${REALSENSE_MSGS_SHA}"; \
    cp -a realsense2_camera_msgs /ws/src/; \
    rm -rf /tmp/realsense-ros

# Add the detection packages and default model files to the image.
RUN set -eux; \
    git clone \
        --depth 1 \
        --branch "${OBJECT_DETECTION_REF}" \
        "${OBJECT_DETECTION_REPO}" \
        /tmp/fre-object-detection; \
    cp -a /tmp/fre-object-detection/ros2_detection /ws/src/; \
    cp -a /tmp/fre-object-detection/ros2_detection_interfaces /ws/src/; \
    cp -a /tmp/fre-object-detection/model/. /ws/model/; \
    rm -rf /tmp/fre-object-detection

RUN set -eux; \
    source /opt/ros/humble/setup.bash; \
    colcon build \
        --symlink-install \
        --packages-select \
            realsense2_camera_msgs \
            ros2_detection_interfaces \
            ros2_detection \
        --cmake-args \
            -DCMAKE_BUILD_TYPE=Release; \
    source /ws/install/setup.bash; \
    ros2 interface show realsense2_camera_msgs/msg/RGBD; \
    python3 -c "import cv2, torch, sklearn, ultralytics, pyrealsense2; \
print('Torch:', torch.__version__, 'CUDA build:', torch.version.cuda); \
print('OpenCV:', cv2.__version__); \
print('Ultralytics:', ultralytics.__version__)"

ENV ROS_DOMAIN_ID=0 \
    RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

COPY object_detection/entrypoint.sh /entrypoint.sh
COPY object_detection/start_object_detection.sh /start_object_detection.sh

RUN chmod +x \
    /entrypoint.sh \
    /start_object_detection.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/start_object_detection.sh"]
