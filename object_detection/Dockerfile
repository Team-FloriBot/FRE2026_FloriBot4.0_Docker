FROM ros:humble

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DOMAIN_ID=0
ENV RMW_IMPLEMENTATION=rmw_fastrtps_cpp
ENV ULTRALYTICS_CONFIG_DIR=/tmp

WORKDIR /ws

ARG OBJECT_DETECTION_REPO=https://github.com/Team-FloriBot/FRE_object_detection.git
ARG OBJECT_DETECTION_BRANCH=docker_ros2

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    python3-pip \
    python3-setuptools \
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

# ROS 2 Humble ist mit neueren setuptools-Versionen beim ament_python-Build problematisch.
# Daher setuptools explizit auf eine kompatible Version pinnen.
RUN python3 -m pip install --no-cache-dir --upgrade pip wheel && \
    python3 -m pip install --no-cache-dir "setuptools==58.2.0"

RUN python3 -m pip install --no-cache-dir \
    torch \
    opencv-python \
    scikit-learn \
    pyrealsense2 \
    pyyaml \
    ultralytics

RUN python3 -m pip install --no-cache-dir --force-reinstall "numpy<2.0"

RUN mkdir -p /ws/src /ws/model

RUN git clone --branch ${OBJECT_DETECTION_BRANCH} ${OBJECT_DETECTION_REPO} /tmp/FRE_object_detection && \
    cp -r /tmp/FRE_object_detection/ros2_detection /ws/src/ && \
    cp -r /tmp/FRE_object_detection/ros2_detection_interfaces /ws/src/ && \
    cp -r /tmp/FRE_object_detection/ros2_detection_client /ws/src/ && \
    if [ -d /tmp/FRE_object_detection/model ]; then cp -r /tmp/FRE_object_detection/model/* /ws/model/ || true; fi && \
    rm -rf /tmp/FRE_object_detection

RUN source /opt/ros/humble/setup.bash && \
    rosdep update || true && \
    rosdep install --from-paths /ws/src --ignore-src -r -y || true && \
    colcon build

RUN echo "source /opt/ros/humble/setup.bash" >> /root/.bashrc && \
    echo "source /ws/install/setup.bash" >> /root/.bashrc

COPY object_detection/ros_entrypoint.sh /ros_entrypoint.sh
RUN chmod +x /ros_entrypoint.sh

ENTRYPOINT ["/ros_entrypoint.sh"]
CMD ["ros2", "launch", "ros2_detection", "detector.launch.py"]
