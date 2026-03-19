#!/bin/bash
SIF_PATH=/home/ishakpie/projects/def-rhinehar/ishakpie/opt.sif
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
    conda activate ubp
    # or: conda activate ubp

    python3 /SAILOR/gpu_smoke_test.py
  '