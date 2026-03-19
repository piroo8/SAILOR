#!/bin/bash
SIF_PATH=/home/ishakpie/projects/def-rhinehar/ishakpie/opt_robo_cu128.sif
BIND_DIR=/home/ishakpie/projects/def-rhinehar/ishakpie/Sailor

module load apptainer

apptainer exec --nv \
  --no-home \
  --fakeroot \
  --contain \
  --bind "${BIND_DIR}:/SAILOR" \
  "${SIF_PATH}" \
  bash --login -c '
    source /opt/conda/etc/profile.d/conda.sh
    conda env list
    ldd --version
    # pick one env that you KNOW exists in opt.sif
    conda activate robo
    # or: conda activate ubp

    python3 /SAILOR/gpu_smoke_test.py
  '