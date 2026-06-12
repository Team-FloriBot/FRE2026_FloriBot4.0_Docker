# syntax=docker/dockerfile:1.7

# Object detection container for x86_64 systems with an NVIDIA GPU.
# The RealSense camera is handled by the sensors container. This container
# receives camera data through ROS 2 messages and does not need direct access
# to the camera hardware.
#
# Models are taken from the FRE_object_detection repository during the image
# build and stored under /opt/default_models. At container startup, missing
# models are copied into the writable bind mount /models.
#
# The detector configuration is also taken from the FRE_object_detection
# repository during the image build and installed under
# /etc/floribot/object_detection/detector_params.yaml.

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
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    MODEL_DIRECTORY=/models \
    DEFAULT_MODEL_DIRECTORY=/opt/default_models \
    DETECTOR_CONFIG_FILE=/etc/floribot/object_detection/detector_params.yaml

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
    curl -fsSL \
        https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
        -o /usr/share/keyrings/ros-archive-keyring.gpg; \
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME}") main" \
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

# Use a virtual environment to avoid Ubuntu 24.04's externally managed Python
# restriction. --system-site-packages keeps ROS Python modules and cv_bridge
# from /opt/ros/jazzy visible inside the environment.
RUN python3 -m venv \
        --system-site-packages \
        "${VIRTUAL_ENV}" && \
    python -m pip install \
        --upgrade \
        pip \
        setuptools \
        wheel && \
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

RUN mkdir -p \
        /ws/src \
        /tmp/ultralytics \
        /opt/default_models \
        /etc/floribot/object_detection

# Build the exact RealSense message definitions used by the Jazzy sensors
# container. Only the message package is copied; the camera driver is not.
RUN set -eux; \
    git clone \
        --no-checkout \
        "${REALSENSE_MSGS_REPO}" \
        /tmp/realsense-ros; \
    cd /tmp/realsense-ros; \
    git fetch \
        --depth 1 \
        origin \
        "${REALSENSE_MSGS_SHA}"; \
    git checkout \
        --detach \
        FETCH_HEAD; \
    test "$(git rev-parse HEAD)" = "${REALSENSE_MSGS_SHA}"; \
    cp -a \
        realsense2_camera_msgs \
        /ws/src/; \
    rm -rf \
        /tmp/realsense-ros

# Clone the object-detection repository.
#
# Repository models are copied into /opt/default_models. They remain part of
# the image and are copied into /models by start_object_detection.sh when they
# are missing from the mounted model directory.
#
# The detector parameter file is copied into /etc/floribot/object_detection
# so the container does not depend on a host-side bind mount for the config.
RUN set -eux; \
    git clone \
        --depth 1 \
        --branch "${OBJECT_DETECTION_REF}" \
        "${OBJECT_DETECTION_REPO}" \
        /tmp/fre-object-detection; \
    test -d /tmp/fre-object-detection/model; \
    test -f /tmp/fre-object-detection/ros2_detection/params/detector_params.yaml; \
    cp -v \
        /tmp/fre-object-detection/ros2_detection/params/detector_params.yaml \
        /etc/floribot/object_detection/detector_params.yaml; \
    find /tmp/fre-object-detection/model \
        -maxdepth 1 \
        -type f \
        \( \
            -iname '*.pt' \
            -o -iname '*.pth' \
            -o -iname '*.onnx' \
            -o -iname '*.engine' \
        \) \
        -exec cp -v {} /opt/default_models/ \;; \
    echo "Detector config copied from object-detection repository:"; \
    ls -l /etc/floribot/object_detection/detector_params.yaml; \
    echo "Models copied from object-detection repository:"; \
    find /opt/default_models \
        -maxdepth 1 \
        -type f \
        -printf '%f\n' \
        | sort; \
    test -n "$(find /opt/default_models -maxdepth 1 -type f -print -quit)"

# Patch detector_node.py before the ROS workspace is built.
#
# The detector:
# - uses /models as neutral model directory,
# - reads the directory from the model_directory ROS parameter,
# - publishes absolute model paths on /detector/available_models,
# - uses transient-local QoS so late subscribers receive the last model list,
# - treats classes: [] in YAML as an empty class filter instead of failing.
RUN python3 - <<'PYCODE'
from pathlib import Path


detector_node = Path(
    "/tmp/fre-object-detection/"
    "ros2_detection/ros2_detection/detector_node.py"
)

text = detector_node.read_text(encoding="utf-8")


def replace_once(old: str, new: str, description: str) -> None:
    global text

    if old not in text:
        raise RuntimeError(
            f"Could not patch {description}: expected source was not found "
            f"in {detector_node}"
        )

    text = text.replace(old, new, 1)


replace_once(
    "from rclpy.node import Node\n",
    (
        "from rclpy.node import Node\n"
        "from rclpy.exceptions import ParameterUninitializedException\n"
        "from rclpy.qos import (\n"
        "    DurabilityPolicy,\n"
        "    HistoryPolicy,\n"
        "    QoSProfile,\n"
        "    ReliabilityPolicy,\n"
        ")\n"
    ),
    "QoS and parameter exception imports",
)

replace_once(
    '        self.declare_parameter("model_path", "")\n',
    (
        '        self.declare_parameter("model_path", "")\n'
        '        self.declare_parameter("model_directory", "/models")\n'
    ),
    "model_directory parameter declaration",
)

replace_once(
    '        self.node_params = {\n',
    (
        '        try:\n'
        '            configured_classes = self.get_parameter("classes").value\n'
        '        except ParameterUninitializedException:\n'
        '            configured_classes = []\n'
        '\n'
        '        if configured_classes is None:\n'
        '            configured_classes = []\n'
        '\n'
        '        configured_classes = [\n'
        '            str(class_name).strip()\n'
        '            for class_name in configured_classes\n'
        '            if str(class_name).strip()\n'
        '        ]\n'
        '\n'
        '        self.node_params = {\n'
    ),
    "robust classes parameter read",
)

replace_once(
    '            "classes": self.get_parameter("classes").value,\n',
    '            "classes": configured_classes,\n',
    "classes parameter mapping",
)

replace_once(
    '            "model_path": self.get_parameter("model_path").value,\n',
    (
        '            "model_path": self.get_parameter("model_path").value,\n'
        '            "model_directory": '
        'self.get_parameter("model_directory").value,\n'
    ),
    "model_directory parameter mapping",
)

old_publisher = '''        self.available_models_pub = self.create_publisher(
            String,
            self.node_params.get(
                "available_models_topic",
                "/detector/available_models",
            ),
            10,
        )
'''

new_publisher = '''        available_models_qos = QoSProfile(
            history=HistoryPolicy.KEEP_LAST,
            depth=1,
            reliability=ReliabilityPolicy.RELIABLE,
            durability=DurabilityPolicy.TRANSIENT_LOCAL,
        )

        self.available_models_pub = self.create_publisher(
            String,
            self.node_params.get(
                "available_models_topic",
                "/detector/available_models",
            ),
            available_models_qos,
        )
'''

if old_publisher in text:
    replace_once(
        old_publisher,
        new_publisher,
        "available_models publisher QoS",
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

        supported_extensions = {
            ".pt",
            ".pth",
            ".onnx",
            ".engine",
        }

        model_paths: List[str] = []

        for filename in sorted(os.listdir(model_dir)):
            full_path = os.path.join(model_dir, filename)

            if not os.path.isfile(full_path):
                continue

            extension = os.path.splitext(filename)[1].lower()

            if extension not in supported_extensions:
                continue

            model_paths.append(full_path)

        return model_paths
'''

replace_once(
    old_model_scan,
    new_model_scan,
    "_get_available_model_paths",
)

detector_node.write_text(text, encoding="utf-8")

print(f"Patched model directory handling in {detector_node}")
PYCODE

# Enforce the intended camera ownership model.
# The RealSense pipeline is owned by the sensors container. The detector only
# consumes RGBD ROS messages and must not open the USB camera directly.
RUN python3 - <<'PYCODE'
from pathlib import Path

model = Path(
    "/tmp/fre-object-detection/"
    "ros2_detection/ros2_detection/detection_model_selection.py"
)
text = model.read_text(encoding="utf-8")
old = '''        if self.get_realsense_images is not None:
            # start realsense node if not already done?
            self.is_initialized = True
            
        else:
            """
            Initialises the RealSense pipeline and starts streaming.
            """
'''
new = '''        if self.get_realsense_images is not None:
            self.is_initialized = True
            return

        raise RuntimeError(
            "Direct RealSense pipeline access is disabled in the object-detection container. "
            "Start realsense2_camera in the sensors container and provide get_realsense_images."
        )

        # Unreachable fallback kept below for upstream diff stability.
        if False:
            """
            Initialises the RealSense pipeline and starts streaming.
            """
'''
if old not in text:
    raise RuntimeError("Could not patch direct RealSense fallback")
model.write_text(text.replace(old, new, 1), encoding="utf-8")
print("Patched detector to subscribe only to RGBD ROS messages")
PYCODE

# Copy the patched ROS packages into the workspace.
RUN set -eux; \
    cp -a \
        /tmp/fre-object-detection/ros2_detection \
        /ws/src/; \
    cp -a \
        /tmp/fre-object-detection/ros2_detection_interfaces \
        /ws/src/; \
    rm -rf \
        /tmp/fre-object-detection

# Build the ROS workspace.
#
# Do not enable nounset while sourcing ROS setup files. Some generated setup
# scripts reference optional variables that may not exist yet.
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
    test \
        "$(head -n 1 /ws/install/ros2_detection/lib/ros2_detection/detector_node)" \
        = "#!/opt/venv/bin/python3"; \
    test -f /etc/floribot/object_detection/detector_params.yaml; \
    grep -q "configured_classes" \
        /ws/install/ros2_detection/lib/python3.12/site-packages/ros2_detection/detector_node.py; \
    ros2 interface show \
        realsense2_camera_msgs/msg/RGBD; \
    python -c "\
import cv2; \
import pyrealsense2; \
import sklearn; \
import torch; \
import ultralytics; \
print('Python environment: Jazzy / Python 3.12'); \
print('Torch:', torch.__version__, 'CUDA build:', torch.version.cuda); \
print('OpenCV:', cv2.__version__); \
print('Ultralytics:', ultralytics.__version__)"

ENV ROS_DOMAIN_ID=0 \
    RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

# Automatically source ROS 2 and the workspace in interactive Bash shells.
RUN printf '%s\n' \
        'source /opt/ros/${ROS_DISTRO:-jazzy}/setup.bash' \
        '[ -f /ws/install/setup.bash ] && source /ws/install/setup.bash' \
        >> /root/.bashrc

COPY object_detection/entrypoint.sh \
    /entrypoint.sh

COPY object_detection/start_object_detection.sh \
    /start_object_detection.sh

RUN chmod +x \
    /entrypoint.sh \
    /start_object_detection.sh

ENTRYPOINT ["/entrypoint.sh"]

CMD ["/start_object_detection.sh"]
