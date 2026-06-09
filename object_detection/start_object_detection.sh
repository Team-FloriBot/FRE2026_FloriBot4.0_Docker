#!/bin/bash
set -euo pipefail

MODEL_DIRECTORY="${MODEL_DIRECTORY:-/models}"
DEFAULT_MODEL_DIRECTORY="${DEFAULT_MODEL_DIRECTORY:-/opt/default_models}"

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

exec ros2 launch \
    ros2_detection \
    detector.launch.py \
    --ros-args \
    -p model_directory:="${MODEL_DIRECTORY}"
