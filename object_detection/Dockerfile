# ROS 2 Humble base image
FROM ros:humble

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DOMAIN_ID=0
ENV RMW_IMPLEMENTATION=rmw_fastrtps_cpp
ENV ULTRALYTICS_CONFIG_DIR=/tmp

WORKDIR /ws

# GitHub repository
ARG OBJECT_DETECTION_REPO=https://github.com/Team-FloriBot/FRE_object_detection.git
ARG OBJECT_DETECTION_BRANCH=main

# System dependencies
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

# Python dependencies
RUN python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel

# numpy < 2.0 wegen ROS cv_bridge / OpenCV-Kompatibilität
RUN python3 -m pip install --no-cache-dir "numpy<2.0"

RUN python3 -m pip install --no-cache-dir \
    torch \
    opencv-python \
    scikit-learn \
    pyrealsense2 \
    pyyaml \
    ultralytics

# Create ROS 2 workspace
RUN mkdir -p /ws/src

# Clone object detection repository from GitHub
RUN git clone --branch ${OBJECT_DETECTION_BRANCH} ${OBJECT_DETECTION_REPO} /tmp/FRE_object_detection && \
    cp -r /tmp/FRE_object_detection/ros2_detection /ws/src/ && \
    cp -r /tmp/FRE_object_detection/ros2_detection_interfaces /ws/src/ && \
    cp -r /tmp/FRE_object_detection/ros2_detection_client /ws/src/ && \
    mkdir -p /ws/model && \
    if [ -d /tmp/FRE_object_detection/model ]; then cp -r /tmp/FRE_object_detection/model/* /ws/model/; fi && \
    rm -rf /tmp/FRE_object_detection

# Install ROS dependencies and build workspace
RUN source /opt/ros/humble/setup.bash && \
    rosdep update || true && \
    rosdep install --from-paths /ws/src --ignore-src -r -y || true && \
    colcon build --symlink-install

# Source ROS and workspace automatically
RUN echo "source /opt/ros/humble/setup.bash" >> /root/.bashrc && \
    echo "source /ws/install/setup.bash" >> /root/.bashrc

CMD ["/bin/bash"]
