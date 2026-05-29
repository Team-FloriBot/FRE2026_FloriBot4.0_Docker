# syntax=docker/dockerfile:1

# Object detection container for NVIDIA Jetson Xavier / JetPack 5 (L4T R35).
# The sensors container owns the RealSense hardware and publishes RGBD messages.
# This container nevertheless requires pyrealsense2 because ros2_detection
# imports pyrealsense2 and constructs RealSense processing filters internally.

ARG JETSON_ROS_IMAGE=dustynv/ros:humble-pytorch-l4t-r35.3.1
FROM ${JETSON_ROS_IMAGE}

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=humble

ENV ULTRALYTICS_CONFIG_DIR=/tmp
ENV YOLO_CONFIG_DIR=/tmp

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

# Increase pip robustness for large ARM64 wheel downloads on the Jetson.
ENV PIP_DEFAULT_TIMEOUT=600
ENV PIP_RETRIES=10
ENV PIP_DISABLE_PIP_VERSION_CHECK=1

# Libraries installed from source are placed below /usr/local.
ENV CMAKE_PREFIX_PATH=/usr/local:${CMAKE_PREFIX_PATH}
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH}
ENV LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}

WORKDIR /ws

# ROS vision packages required for cv_bridge.
ARG VISION_OPENCV_REPO=https://github.com/ros-perception/vision_opencv.git
ARG VISION_OPENCV_REF=humble

# Required for the RGBD ROS message definition.
ARG REALSENSE_MSGS_REPO=https://github.com/realsenseai/realsense-ros.git
ARG REALSENSE_MSGS_REF=ros2-master

# Required by ros2_detection because detection_model_selection.py imports
# pyrealsense2 and constructs RealSense processing filter objects.
ARG LIBREALSENSE_REPO=https://github.com/IntelRealSense/librealsense.git
ARG LIBREALSENSE_REF=v2.57.7

# CycloneDDS middleware used by the FloriBot ROS containers.
ARG CYCLONEDDS_REPO=https://github.com/eclipse-cyclonedds/cyclonedds.git
ARG CYCLONEDDS_REF=0.10.5
ARG RMW_CYCLONEDDS_REPO=https://github.com/ros2/rmw_cyclonedds.git
ARG RMW_CYCLONEDDS_REF=humble

# FloriBot object detection ROS 2 packages and YOLO model files.
ARG OBJECT_DETECTION_REPO=https://github.com/Team-FloriBot/FRE_object_detection.git
ARG OBJECT_DETECTION_REF=docker_ros2

# The Jetson ROS base image contains an inherited ROS 2 APT source whose key
# may no longer be valid. ROS Humble itself is already supplied by the image.
# Additional ROS packages are built from source in this container.
RUN set -eux; \
    for source in /etc/apt/sources.list /etc/apt/sources.list.d/*.list; do \
        [ -f "${source}" ] || continue; \
        sed -i '\|packages\.ros\.org/ros2/ubuntu|d' "${source}"; \
    done

# Do not install python3-opencv or libopencv-dev here.
# The Jetson base image already provides NVIDIA-compatible OpenCV packages.
# Installing Ubuntu repository variants can overwrite NVIDIA/OpenCV files.
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    cmake \
    pkg-config \
    python3-pip \
    python3-dev \
    python3-setuptools \
    python3-colcon-common-extensions \
    python3-numpy \
    libboost-dev \
    libusb-1.0-0-dev \
    libudev-dev \
    libssl-dev \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    && rm -rf /var/lib/apt/lists/*

# CUDA-enabled torch, torchvision and OpenCV are supplied by the Jetson base image.
# Keep a persistent pip cache so interrupted downloads of large ARM64 wheels such
# as scipy do not have to be restarted from zero on every Docker build.
RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m pip install \
        --timeout 600 \
        --retries 10 \
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
        ultralytics-thop && \
    python3 -m pip install \
        --timeout 600 \
        --retries 10 \
        --prefer-binary \
        --no-deps \
        "ultralytics==8.4.48"

# Build librealsense with Python bindings.
# ros2_detection requires pyrealsense2 even though RGBD image data are supplied
# through ROS topics by the separate sensors container.
RUN set -eux; \
    PYTHON_INSTALL_DIR="$(python3 -c 'import site; paths=site.getsitepackages(); print(next((p for p in paths if p.startswith("/usr/local/")), paths[0]))')"; \
    echo "Installing pyrealsense2 into Python-visible directory: ${PYTHON_INSTALL_DIR}"; \
    git clone --depth 1 --branch "${LIBREALSENSE_REF}" \
        "${LIBREALSENSE_REPO}" /opt/librealsense; \
    mkdir -p /opt/librealsense/build; \
    cd /opt/librealsense/build; \
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_EXAMPLES=OFF \
        -DBUILD_GRAPHICAL_EXAMPLES=OFF \
        -DBUILD_TOOLS=OFF \
        -DBUILD_UNIT_TESTS=OFF \
        -DBUILD_PYTHON_BINDINGS=ON \
        -DBUILD_PYTHON_DOCS=OFF \
        -DBUILD_WITH_CUDA=OFF \
        -DFORCE_RSUSB_BACKEND=ON \
        -DIMPORT_DEPTH_CAM_FW=OFF \
        -DPYTHON_EXECUTABLE="$(command -v python3)" \
        -DPYTHON_INSTALL_DIR="${PYTHON_INSTALL_DIR}"; \
    make -j"$(nproc)"; \
    make install; \
    ldconfig; \
    python3 -c "import pyrealsense2 as rs; print('pyrealsense2 available:', rs.__file__)"; \
    rm -rf /opt/librealsense

# Clone ROS dependencies and copy only the required source packages into /ws/src.
RUN mkdir -p /ws/src /ws/model && \
    git clone --depth 1 --branch "${VISION_OPENCV_REF}" \
        "${VISION_OPENCV_REPO}" /ws/src/vision_opencv && \
    git clone --depth 1 --branch "${REALSENSE_MSGS_REF}" \
        "${REALSENSE_MSGS_REPO}" /tmp/realsense-msgs-source && \
    cp -r /tmp/realsense-msgs-source/realsense2_camera_msgs /ws/src/ && \
    rm -rf /tmp/realsense-msgs-source && \
    git clone --depth 1 --branch "${CYCLONEDDS_REF}" \
        "${CYCLONEDDS_REPO}" /ws/src/cyclonedds && \
    git clone --depth 1 --branch "${RMW_CYCLONEDDS_REF}" \
        "${RMW_CYCLONEDDS_REPO}" /ws/src/rmw_cyclonedds && \
    git clone --depth 1 --branch "${OBJECT_DETECTION_REF}" \
        "${OBJECT_DETECTION_REPO}" /tmp/fre-object-detection && \
    cp -r /tmp/fre-object-detection/ros2_detection /ws/src/ && \
    cp -r /tmp/fre-object-detection/ros2_detection_interfaces /ws/src/ && \
    cp -r /tmp/fre-object-detection/model/. /ws/model/ && \
    rm -rf /tmp/fre-object-detection

# Build CycloneDDS without ddsperf.
# The optional ddsperf target invokes idlc during compilation and fails in this
# base image because an incompatible CycloneDDS shared library is resolved.
RUN source /opt/ros/humble/install/setup.bash && \
    colcon build --symlink-install --packages-select cyclonedds \
        --cmake-args \
            -DBUILD_DDSPERF=OFF \
            -DBUILD_EXAMPLES=OFF \
            -DBUILD_TESTING=OFF

# Build the remaining ROS packages against the CycloneDDS workspace overlay.
RUN source /opt/ros/humble/install/setup.bash && \
    source /ws/install/setup.bash && \
    colcon build --symlink-install --packages-select \
        rmw_cyclonedds_cpp \
        cv_bridge \
        realsense2_camera_msgs \
        ros2_detection_interfaces \
        ros2_detection

# Make ROS and workspace packages directly available in interactive shells.
RUN echo 'if [ -f /opt/ros/humble/install/setup.bash ]; then source /opt/ros/humble/install/setup.bash; elif [ -f /opt/ros/humble/setup.bash ]; then source /opt/ros/humble/setup.bash; fi' >> /etc/bash.bashrc && \
    echo 'if [ -f /ws/install/setup.bash ]; then source /ws/install/setup.bash; fi' >> /etc/bash.bashrc

# Container-specific startup scripts remain part of the Docker repository.
COPY object_detection/entrypoint.sh /entrypoint.sh
COPY object_detection/start_object_detection.sh /start_object_detection.sh

RUN chmod +x /entrypoint.sh /start_object_detection.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/start_object_detection.sh"]
