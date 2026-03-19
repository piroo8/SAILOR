#!/bin/bash
SIF_PATH=/home/ishakpie/projects/def-rhinehar/ishakpie/opt_robo_cu128_cvfix.sif

module load apptainer

apptainer exec --nv \
  --no-home \
  --fakeroot \
  --contain \
  --bind /home/ishakpie/projects/def-rhinehar/ishakpie/Sailor:/SAILOR \
  "$SIF_PATH" \
  bash -lc '
    source /opt/conda/etc/profile.d/conda.sh
    conda activate robo

    # Writable dirs (matplotlib/fontconfig/numba)
    export HOME=/tmp/home
    export XDG_CACHE_HOME=/tmp/xdg-cache
    export MPLCONFIGDIR=/tmp/mplconfig
    export FC_CACHEDIR=/tmp/fontconfig
    export NUMBA_CACHE_DIR=/tmp/numba-cache
    export NUMBA_DISABLE_CACHING=1
    mkdir -p "$HOME" "$XDG_CACHE_HOME" "$MPLCONFIGDIR" "$FC_CACHEDIR" "$NUMBA_CACHE_DIR"

    # Prefer conda env shared libs
    export LD_LIBRARY_PATH="$CONDA_PREFIX/lib:/opt/conda/lib:${LD_LIBRARY_PATH:-}"

    # Force correct jpeg to avoid libtiff/libjpeg ABI mismatch
    export LD_PRELOAD="$CONDA_PREFIX/lib/libjpeg.so.8:${LD_PRELOAD:-}"

    export MUJOCO_GL=osmesa
    #export EGL_PLATFORM=surfaceless
    #export __GLX_VENDOR_LIBRARY_NAME=nvidia
    # This helps EGL find the NVIDIA vendor json on many systems:
    #export __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/10_nvidia.json


    # Quick sanity check
    python - <<PY
import cv2
print("cv2 OK:", cv2.__version__)
PY

python - <<PY
import torch
print("torch:", torch.__version__)
print("cuda available:", torch.cuda.is_available())
if torch.cuda.is_available():
    print("gpu:", torch.cuda.get_device_name(0))
    x = torch.randn(4096,4096, device="cuda")
    y = torch.randn(4096,4096, device="cuda")
    z = x @ y
    torch.cuda.synchronize()
    print("gpu matmul OK, mean:", z.mean().item())
PY

    # Run the real command
    cd /SAILOR
    python3 -m robomimic.scripts.dataset_states_to_obs \
      --done_mode 1 \
      --dataset datasets/robomimic_datasets/can/ph/demo_v141.hdf5 \
      --output_name image_64_shaped_done1_v141.hdf5 \
      --camera_names agentview robot0_eye_in_hand \
      --camera_height 64 \
      --camera_width 64 \
      --shaped
  '
