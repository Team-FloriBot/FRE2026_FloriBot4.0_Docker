#!/bin/bash
set -euo pipefail

# Some scikit-learn wheels bundle their own OpenMP runtime. Locate it for the
# active Python version instead of using a hard-coded site-packages path.
SKLEARN_LIBGOMP="$(python - <<'PYCODE'
import glob
import site

patterns = []
for base in dict.fromkeys(site.getsitepackages() + [site.getusersitepackages()]):
    patterns.extend([
        f"{base}/scikit_learn.libs/libgomp*.so*",
        f"{base}/sklearn/.libs/libgomp*.so*",
    ])

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
    echo "No bundled scikit-learn OpenMP runtime found; using the system runtime."
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

if [ ! -d /models ]; then
    echo "ERROR: Model directory /models does not exist." >&2
    exit 1
fi

echo "Available object-detection models:"
find /models \
    -maxdepth 1 \
    -type f \
    \( \
        -iname '*.pt' \
        -o -iname '*.pth' \
        -o -iname '*.onnx' \
        -o -iname '*.engine' \
    \) \
    -print \
    | sort

exec ros2 launch ros2_detection detector.launch.py
