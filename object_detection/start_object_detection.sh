#!/bin/bash
set -euo pipefail

MODEL_DIRECTORY="${MODEL_DIRECTORY:-/models}"
DEFAULT_MODEL_DIRECTORY="${DEFAULT_MODEL_DIRECTORY:-/opt/default_models}"
DETECTOR_CONFIG_FILE="${DETECTOR_CONFIG_FILE:-/etc/floribot/object_detection/detector_params.yaml}"
DETECTOR_RGBD_TOPIC="${DETECTOR_RGBD_TOPIC:-/sensors/realsense_front/rgbd}"
DETECTOR_USE_REALSENSE_ROS_WRAPPER="${DETECTOR_USE_REALSENSE_ROS_WRAPPER:-false}"

SKLEARN_LIBGOMP="$(
python - <<'PYCODE'
import glob
import site

patterns = []

for base in dict.fromkeys(
    site.getsitepackages() + [site.getusersitepackages()]
):
    patterns.extend(
        [
            f"{base}/scikit_learn.libs/libgomp*.so*",
            f"{base}/sklearn/.libs/libgomp*.so*",
        ]
    )

matches = []

for pattern in patterns:
    matches.extend(glob.glob(pattern))

print(matches[0] if matches else "")
PYCODE
)"

if [ -n "${SKLEARN_LIBGOMP}" ]; then
    export LD_PRELOAD="${SKLEARN_LIBGOMP}${LD_PRELOAD:+:${LD_PRELOAD}}"
    echo "Preloading OpenMP runtime: ${SKLEARN_LIBGOMP}"
else
    echo "No bundled scikit-learn OpenMP runtime found."
fi

python - <<'PYCODE'
import cv2
import torch
import torchvision
from sklearn.neighbors import NearestNeighbors
from ultralytics import YOLO

print("ROS distribution: Jazzy")
print("CUDA available:", torch.cuda.is_available())
print("PyTorch:", torch.__version__)
print("Torchvision:", torchvision.__version__)
print("OpenCV:", cv2.__version__)
print("Python dependency import test: OK")
PYCODE

mkdir -p "${MODEL_DIRECTORY}"

if [ -d "${DEFAULT_MODEL_DIRECTORY}" ]; then
    echo "Synchronizing repository models into ${MODEL_DIRECTORY}"

    find "${DEFAULT_MODEL_DIRECTORY}" \
        -maxdepth 1 \
        -type f \
        \( \
            -iname '*.pt' \
            -o -iname '*.pth' \
            -o -iname '*.onnx' \
            -o -iname '*.engine' \
        \) \
        -print0 \
        | while IFS= read -r -d '' source_model; do
            filename="$(basename "${source_model}")"
            target_model="${MODEL_DIRECTORY}/${filename}"

            if [ ! -f "${target_model}" ]; then
                echo "Copying model: ${filename}"
                cp "${source_model}" "${target_model}"
            else
                echo "Model already exists: ${filename}"
            fi
        done
fi

echo "Models available in ${MODEL_DIRECTORY}:"

find "${MODEL_DIRECTORY}" \
    -maxdepth 1 \
    -type f \
    \( \
        -iname '*.pt' \
        -o -iname '*.pth' \
        -o -iname '*.onnx' \
        -o -iname '*.engine' \
    \) \
    -printf '%f\n' \
    | sort

if [ ! -f "${DETECTOR_CONFIG_FILE}" ]; then
    echo "Detector config file not found: ${DETECTOR_CONFIG_FILE}" >&2
    exit 1
fi

exec ros2 run \
    ros2_detection \
    detector_node \
    --ros-args \
    --params-file "${DETECTOR_CONFIG_FILE}" \
    -p model_directory:="${MODEL_DIRECTORY}" \
    -p use_realsense_ros_wrapper:="${DETECTOR_USE_REALSENSE_ROS_WRAPPER}" \
    -p rgbd_topic:="${DETECTOR_RGBD_TOPIC}"
