# syntax=docker/dockerfile:1.7

# Object detection container for x86_64 systems with an NVIDIA GPU.
# The RealSense camera is handled by the sensors container. This container
# receives the camera data through ROS 2 messages and therefore does not need
# direct access to the camera hardware.
# pyrealsense2 is required by detection_model_selection.py.

ARG CUDA_IMAGE=nvidia/cuda:12.6.3-cudnn-devel-ubuntu24.04
FROM ${CUDA_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV DEBIAN_FRONTEND=noninteractive \
    ROS_DISTRO=jazzy \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    VIRTUAL_ENV=/opt/venv \
    PATH=/opt/venv/bin:${PATH} \
    ULTRALYTICS_CONFIG_DIR=/tmp/ultralytics \
    YOLO_CONFIG_DIR=/tmp/ultralytics \
    NVIDIA_VISIBLE_DEVICES=all \
    NVIDIA_DRIVER_CAPABILITIES=compute,utility \
    PIP_DEFAULT_TIMEOUT=600 \
    PIP_RETRIES=10 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /ws

# Keep this commit identical to the sensors container. Otherwise the generated
# DDS type support for realsense2_camera_msgs can become incompatible.
ARG REALSENSE_MSGS_REPO=https://github.com/realsenseai/realsense-ros.git
ARG REALSENSE_MSGS_SHA=6d87b071dcfef15f2a0407e1e78945256add70d0
ARG OBJECT_DETECTION_REPO=https://github.com/Team-FloriBot/FRE_object_detection.git
ARG OBJECT_DETECTION_REF=docker_ros2
ARG PYTORCH_CUDA_INDEX=https://download.pytorch.org/whl/cu124

# ROS 2 Jazzy and build/runtime dependencies for Ubuntu 24.04.
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
        python3-venv \
        python3-setuptools \
        python3-colcon-common-extensions \
        python3-rosdep \
        ros-jazzy-ros-base \
        ros-jazzy-cv-bridge \
        ros-jazzy-image-transport \
        ros-jazzy-sensor-msgs \
        ros-jazzy-rmw-cyclonedds-cpp \
        libgl1 \
        libglib2.0-0 \
        libsm6 \
        libxext6; \
    rm -rf /var/lib/apt/lists/*

# Use a virtual environment to avoid Ubuntu 24.04's externally-managed Python
# restriction. --system-site-packages keeps ROS Python modules and cv_bridge
# from /opt/ros/jazzy visible inside the environment.
RUN python3 -m venv --system-site-packages "${VIRTUAL_ENV}" && \
    python -m pip install --upgrade pip setuptools wheel && \
    python -m pip install \
        --index-url "${PYTORCH_CUDA_INDEX}" \
        torch==2.5.1 \
        torchvision==0.20.1 && \
    python -m pip install \
        --prefer-binary \
        "numpy<2.0" \
        pyyaml \
        "scikit-learn==1.5.2" \
        pillow \
        requests \
        "scipy==1.13.1" \
        psutil \
        matplotlib \
        polars \
        pyrealsense2==2.58.1.10581 \
        ultralytics-thop && \
    python -m pip install \
        --no-deps \
        "ultralytics==8.4.48"

RUN mkdir -p /ws/src /tmp/ultralytics

# Build the exact RealSense message definitions used by the Jazzy sensors
# container. Only the message package is copied; the camera driver is not.
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

# Clone the object-detection repository.
# Model files are not copied into the image. They are mounted at runtime
# through the Docker Compose volume at /models.
RUN set -eux; \
    git clone \
        --depth 1 \
        --branch "${OBJECT_DETECTION_REF}" \
        "${OBJECT_DETECTION_REPO}" \
        /tmp/fre-object-detection

# Patch detector_node.py before the ROS workspace is built.
# The detector scans the neutral model directory /models and publishes
# absolute model paths on /detector/available_models.
RUN python3 - <<'PYCODE'
from pathlib import Path

detector_node = Path(
    "/tmp/fre-object-detection/"
    "ros2_detection/ros2_detection/detector_node.py"
)

text = detector_node.read_text(encoding="utf-8")

old_parameter_declaration = (
    '        self.declare_parameter("model_path", "")\n'
)

new_parameter_declaration = (
    '        self.declare_parameter("model_path", "")\n'
    '        self.declare_parameter("model_directory", "/models")\n'
)

if old_parameter_declaration not in text:
    raise RuntimeError(
        "Could not find the model_path parameter declaration in "
        f"{detector_node}"
    )

text = text.replace(
    old_parameter_declaration,
    new_parameter_declaration,
    1,
)

old_parameter_mapping = (
    '            "model_path": self.get_parameter("model_path").value,\n'
)

new_parameter_mapping = (
    '            "model_path": self.get_parameter("model_path").value,\n'
    '            "model_directory": '
    'self.get_parameter("model_directory").value,\n'
)

if old_parameter_mapping not in text:
    raise RuntimeError(
        "Could not find the model_path node_params entry in "
        f"{detector_node}"
    )

text = text.replace(
    old_parameter_mapping,
    new_parameter_mapping,
    1,
)

old_model_scan = '''    def _get_available_model_paths(self) -> List[str]:
        """Return model files as relative paths matching the init request format."""
        module_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        repo_root = os.path.dirname(module_root)
        model_dir = os.path.join(repo_root, "model")

        if not os.path.isdir(model_dir):
            return []

        supported_extensions = {".pt", ".pth", ".onnx", ".engine"}
        model_paths = []
        for filename in sorted(os.listdir(model_dir)):
            full_path = os.path.join(model_dir, filename)
            if not os.path.isfile(full_path):
                continue

            _, extension = os.path.splitext(filename)
            if extension.lower() not in supported_extensions:
                continue

            model_paths.append(os.path.join("model", filename))

        return model_paths
'''

new_model_scan = '''    def _get_available_model_paths(self) -> List[str]:
        """Return absolute model paths from the configured model directory."""
        model_dir = os.path.abspath(
            os.path.expanduser(
                str(self.node_params.get("model_directory", "/models"))
            )
        )

        if not os.path.isdir(model_dir):
            self.get_logger().warning(
                f"Configured model directory does not exist: {model_dir}"
            )
            return []

        supported_extensions = {".pt", ".pth", ".onnx", ".engine"}
        model_paths = []

        for filename in sorted(os.listdir(model_dir)):
            full_path = os.path.join(model_dir, filename)

            if not os.path.isfile(full_path):
                continue

            _, extension = os.path.splitext(filename)

            if extension.lower() not in supported_extensions:
                continue

            model_paths.append(full_path)

        return model_paths
'''

if old_model_scan not in text:
    raise RuntimeError(
        "Could not find the expected _get_available_model_paths() "
        f"implementation in {detector_node}"
    )

text = text.replace(
    old_model_scan,
    new_model_scan,
    1,
)

detector_node.write_text(text, encoding="utf-8")

print(f"Patched model directory handling in {detector_node}")
PYCODE

# Copy the patched ROS packages into the workspace.
RUN set -eux; \
    cp -a \
        /tmp/fre-object-detection/ros2_detection \
        /ws/src/; \
    cp -a \
        /tmp/fre-object-detection/ros2_detection_interfaces \
        /ws/src/; \
    rm -rf /tmp/fre-object-detection

# Do not enable nounset while sourcing ROS setup files. Some generated setup
# scripts reference optional variables that may not exist yet. A regular install
# is used because the package does not support setuptools editable installs.
RUN set -ex; \
    source /opt/ros/jazzy/setup.bash; \
    /opt/venv/bin/python3 -m colcon build \
        --packages-select \
            realsense2_camera_msgs \
            ros2_detection_interfaces \
            ros2_detection \
        --cmake-args \
            -DCMAKE_BUILD_TYPE=Release; \
    source /ws/install/setup.bash; \
    test "$(head -n 1 /ws/install/ros2_detection/lib/ros2_detection/detector_node)" = "#!/opt/venv/bin/python3"; \
    ros2 interface show realsense2_camera_msgs/msg/RGBD; \
    python -c "import cv2, torch, sklearn, ultralytics, pyrealsense2; \
print('Python environment: Jazzy / Python 3.12'); \
print('Torch:', torch.__version__, 'CUDA build:', torch.version.cuda); \
print('OpenCV:', cv2.__version__); \
print('Ultralytics:', ultralytics.__version__)"

ENV ROS_DOMAIN_ID=0 \
    RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

# Automatically source ROS 2 and the workspace in interactive Bash shells,
# including shells started with: docker exec -it <container> bash
RUN printf '%s\n' \
        'source /opt/ros/${ROS_DISTRO:-jazzy}/setup.bash' \
        '[ -f /ws/install/setup.bash ] && source /ws/install/setup.bash' \
        >> /root/.bashrc

COPY object_detection/entrypoint.sh /entrypoint.sh
COPY object_detection/start_object_detection.sh /start_object_detection.sh

RUN chmod +x \
    /entrypoint.sh \
    /start_object_detection.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/start_object_detection.sh"]
