# Object-Detection-Container für NVIDIA Jetson Xavier / JetPack 5.
#
# Der Sensors-Container besitzt die RealSense-Hardware und veröffentlicht
# realsense2_camera_msgs/msg/RGBD.
#
# Wichtig:
# Der Object-Detection-Container muss exakt dieselbe Version der
# realsense2_camera_msgs verwenden wie der Sensors-Container. Andernfalls
# können CycloneDDS-Deserialisierungsfehler wie
#
#   string data is not null-terminated
#   invalid data size
#
# auftreten.

ARG JETSON_ROS_IMAGE=dustynv/ros:humble-pytorch-l4t-r35.3.1
FROM ${JETSON_ROS_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_DISTRO=humble

# Ultralytics darf seine Konfiguration nicht im schreibgeschützten
# Benutzerverzeichnis ablegen.
ENV ULTRALYTICS_CONFIG_DIR=/tmp
ENV YOLO_CONFIG_DIR=/tmp

# NVIDIA-GPU innerhalb des Containers verfügbar machen.
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

# Stabilere pip-Downloads auf ARM64/Jetson.
ENV PIP_DEFAULT_TIMEOUT=600
ENV PIP_RETRIES=10
ENV PIP_DISABLE_PIP_VERSION_CHECK=1

# Selbst gebaute Bibliotheken werden unter /usr/local installiert.
ENV CMAKE_PREFIX_PATH=/usr/local:${CMAKE_PREFIX_PATH}
ENV PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:${PKG_CONFIG_PATH}
ENV LD_LIBRARY_PATH=/ws/install/lib:/usr/local/lib:${LD_LIBRARY_PATH}

WORKDIR /ws

# ---------------------------------------------------------------------------
# Quellcodeversionen
# ---------------------------------------------------------------------------

ARG VISION_OPENCV_REPO=https://github.com/ros-perception/vision_opencv.git
ARG VISION_OPENCV_REF=humble

# Muss exakt dem REALSENSE_ROS_SHA im Sensors-Dockerfile entsprechen.
ARG REALSENSE_MSGS_REPO=https://github.com/realsenseai/realsense-ros.git
ARG REALSENSE_MSGS_SHA=6d87b071dcfef15f2a0407e1e78945256add70d0

ARG LIBREALSENSE_REPO=https://github.com/IntelRealSense/librealsense.git
ARG LIBREALSENSE_REF=v2.57.7

ARG CYCLONEDDS_REPO=https://github.com/eclipse-cyclonedds/cyclonedds.git
ARG CYCLONEDDS_REF=0.10.5

ARG RMW_CYCLONEDDS_REPO=https://github.com/ros2/rmw_cyclonedds.git
ARG RMW_CYCLONEDDS_REF=humble

ARG OBJECT_DETECTION_REPO=https://github.com/Team-FloriBot/FRE_object_detection.git
ARG OBJECT_DETECTION_REF=docker_ros2

# ---------------------------------------------------------------------------
# APT-Konfiguration
# ---------------------------------------------------------------------------

# Das dustynv-Basisimage enthält ROS 2 bereits. Eine eventuell veraltete
# packages.ros.org-Quelle wird entfernt, damit apt-get update nicht wegen
# eines ungültigen Schlüssels fehlschlägt.
RUN set -eux; \
    for source in /etc/apt/sources.list /etc/apt/sources.list.d/*.list; do \
        [ -f "${source}" ] || continue; \
        sed -i '\|packages\.ros\.org/ros2/ubuntu|d' "${source}"; \
    done

# python3-opencv und libopencv-dev absichtlich nicht installieren.
# Das Jetson-Basisimage stellt eine NVIDIA-kompatible OpenCV-Version bereit.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
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

# ---------------------------------------------------------------------------
# Python-Abhängigkeiten
# ---------------------------------------------------------------------------

# CUDA-fähiges PyTorch, torchvision und OpenCV stammen bereits aus dem
# Jetson-Basisimage und dürfen nicht durch generische pip-Wheels ersetzt werden.
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
        ultralytics-thop \
    && python3 -m pip install \
        --timeout 600 \
        --retries 10 \
        --prefer-binary \
        --no-deps \
        "ultralytics==8.4.48"

# ---------------------------------------------------------------------------
# librealsense und pyrealsense2
# ---------------------------------------------------------------------------

# ros2_detection importiert pyrealsense2 und verwendet RealSense-Filter,
# obwohl die Bilddaten über ein ROS-Topic aus dem Sensors-Container kommen.
RUN set -eux; \
    PYTHON_INSTALL_DIR="$(
        python3 -c \
        'import site; paths=site.getsitepackages(); print(next((p for p in paths if p.startswith("/usr/local/")), paths[0]))'
    )"; \
    echo "Installing pyrealsense2 into: ${PYTHON_INSTALL_DIR}"; \
    git clone \
        --depth 1 \
        --branch "${LIBREALSENSE_REF}" \
        "${LIBREALSENSE_REPO}" \
        /opt/librealsense; \
    cmake \
        -S /opt/librealsense \
        -B /opt/librealsense/build \
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
    cmake \
        --build /opt/librealsense/build \
        --parallel "$(nproc)"; \
    cmake \
        --install /opt/librealsense/build; \
    ldconfig; \
    python3 -c \
        "import pyrealsense2 as rs; print('pyrealsense2 available:', rs.__file__)"; \
    rm -rf /opt/librealsense

# ---------------------------------------------------------------------------
# ROS-2-Quellcode
# ---------------------------------------------------------------------------

RUN set -eux; \
    mkdir -p /ws/src /ws/model; \
    \
    git clone \
        --depth 1 \
        --branch "${VISION_OPENCV_REF}" \
        "${VISION_OPENCV_REPO}" \
        /ws/src/vision_opencv; \
    \
    # Exakten RealSense-Commit auschecken. Kein beweglicher ros2-master-Branch.
    git clone \
        --no-checkout \
        "${REALSENSE_MSGS_REPO}" \
        /tmp/realsense-msgs-source; \
    cd /tmp/realsense-msgs-source; \
    git fetch \
        --depth 1 \
        origin \
        "${REALSENSE_MSGS_SHA}"; \
    git checkout --detach FETCH_HEAD; \
    test "$(git rev-parse HEAD)" = "${REALSENSE_MSGS_SHA}"; \
    cp -a \
        /tmp/realsense-msgs-source/realsense2_camera_msgs \
        /ws/src/; \
    rm -rf /tmp/realsense-msgs-source; \
    \
    git clone \
        --depth 1 \
        --branch "${CYCLONEDDS_REF}" \
        "${CYCLONEDDS_REPO}" \
        /ws/src/cyclonedds; \
    \
    git clone \
        --depth 1 \
        --branch "${RMW_CYCLONEDDS_REF}" \
        "${RMW_CYCLONEDDS_REPO}" \
        /ws/src/rmw_cyclonedds; \
    \
    git clone \
        --depth 1 \
        --branch "${OBJECT_DETECTION_REF}" \
        "${OBJECT_DETECTION_REPO}" \
        /tmp/fre-object-detection; \
    cp -a \
        /tmp/fre-object-detection/ros2_detection \
        /ws/src/; \
    cp -a \
        /tmp/fre-object-detection/ros2_detection_interfaces \
        /ws/src/; \
    cp -a \
        /tmp/fre-object-detection/model/. \
        /ws/model/; \
    rm -rf /tmp/fre-object-detection

# ---------------------------------------------------------------------------
# ROS-2-Workspace bauen
# ---------------------------------------------------------------------------

# CycloneDDS zunächst separat bauen.
#
# BUILD_DDSPERF wird deaktiviert, weil der optionale ddsperf-Build im
# Jetson-Basisimage während des Builds eine inkompatible vorhandene
# CycloneDDS-Bibliothek laden kann.
RUN set -eux; \
    source /opt/ros/humble/install/setup.bash; \
    colcon build \
        --symlink-install \
        --packages-select cyclonedds \
        --cmake-args \
            -DCMAKE_BUILD_TYPE=Release \
            -DBUILD_DDSPERF=OFF \
            -DBUILD_EXAMPLES=OFF \
            -DBUILD_TESTING=OFF

# Alle weiteren Pakete gegen das zuvor gebaute CycloneDDS-Overlay bauen.
RUN set -eux; \
    source /opt/ros/humble/install/setup.bash; \
    source /ws/install/setup.bash; \
    colcon build \
        --symlink-install \
        --packages-select \
            rmw_cyclonedds_cpp \
            cv_bridge \
            realsense2_camera_msgs \
            ros2_detection_interfaces \
            ros2_detection \
        --cmake-args \
            -DCMAKE_BUILD_TYPE=Release

# Build-Ergebnisse und Python-Imports bereits während des Image-Builds prüfen.
RUN set -eux; \
    source /opt/ros/humble/install/setup.bash; \
    source /ws/install/setup.bash; \
    ros2 interface show realsense2_camera_msgs/msg/RGBD; \
    python3 -c "import cv2; print('OpenCV:', cv2.__version__)"; \
    python3 -c "import torch; print('Torch:', torch.__version__, 'CUDA:', torch.cuda.is_available())"; \
    python3 -c "import sklearn; print('scikit-learn:', sklearn.__version__)"; \
    python3 -c "import ultralytics; print('Ultralytics:', ultralytics.__version__)"; \
    test -f /ws/install/rmw_cyclonedds_cpp/lib/librmw_cyclonedds_cpp.so; \
    ldconfig

# ---------------------------------------------------------------------------
# Laufzeitkonfiguration
# ---------------------------------------------------------------------------

ENV ROS_DOMAIN_ID=0
ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

# ROS- und Workspace-Umgebung für interaktive Shells.
RUN printf '%s\n' \
    'if [ -f /opt/ros/humble/install/setup.bash ]; then' \
    '    source /opt/ros/humble/install/setup.bash' \
    'elif [ -f /opt/ros/humble/setup.bash ]; then' \
    '    source /opt/ros/humble/setup.bash' \
    'fi' \
    'if [ -f /ws/install/setup.bash ]; then' \
    '    source /ws/install/setup.bash' \
    'fi' \
    >> /etc/bash.bashrc

COPY object_detection/entrypoint.sh /entrypoint.sh
COPY object_detection/start_object_detection.sh /start_object_detection.sh

RUN chmod +x \
    /entrypoint.sh \
    /start_object_detection.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/start_object_detection.sh"]
