#!/bin/bash
set -e

python3 -c "import torch; print('CUDA available:', torch.cuda.is_available())"

exec ros2 launch ros2_detection detector.launch.py
