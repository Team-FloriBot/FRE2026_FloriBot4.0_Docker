#!/bin/bash
set -euo pipefail

SKLEARN_LIBGOMP="$(find /usr/local/lib/python3.8/dist-packages/scikit_learn.libs \
    -maxdepth 1 -type f -name 'libgomp*.so*' -print -quit)"

if [ -z "${SKLEARN_LIBGOMP}" ]; then
    echo "ERROR: scikit-learn libgomp library not found." >&2
    find /usr/local/lib/python3.8/dist-packages -maxdepth 2 -name 'libgomp*.so*' -print >&2 || true
    exit 1
fi

export LD_PRELOAD="${SKLEARN_LIBGOMP}${LD_PRELOAD:+:${LD_PRELOAD}}"

echo "Preloading OpenMP runtime: ${SKLEARN_LIBGOMP}"

python3 - <<'PY'
import torch
import torchvision
import cv2
import pyrealsense2
from ultralytics import YOLO
from sklearn.neighbors import NearestNeighbors

print("CUDA available:", torch.cuda.is_available())
print("scikit-learn/OpenMP import test: OK")
PY

exec ros2 launch ros2_detection detector.launch.py
