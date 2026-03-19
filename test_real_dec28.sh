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

    # Force correct jpeg (we know this file exists from your ls)
    export LD_PRELOAD="$CONDA_PREFIX/lib/libjpeg.so.8:${LD_PRELOAD:-}"

    python - <<PY
import cv2
print("cv2 OK:", cv2.__version__)
PY
  '

  cd /SAILOR
  TASK=lift
    python3 -m robomimic.scripts.dataset_states_to_obs \
    --done_mode 1 \
    --dataset datasets/robomimic_datasets/lift/ph/demo_v141.hdf5 \
    --output_name image_64_shaped_done1_v141.hdf5 \
    --camera_names agentview robot0_eye_in_hand \
    --camera_height 64 \
    --camera_width 64 \
    --shaped

