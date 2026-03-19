#!/bin/bash
SIF_PATH=/home/ishakpie/projects/def-rhinehar/ishakpie/Sailor/py_2_6_cuda_12_4_cudn_9_devel.sif
SCRIPT_PATH=/Sailor
TEST_FILE=/SAILOR/gpu_smoke_test.py

module load apptainer

apptainer exec --nv \
  --no-home \
  --fakeroot \
  --contain \
  --bind /home/ishakpie/projects/def-rhinehar/ishakpie/Sailor:/mnt/tdmpc2\
  "$SIF_PATH" \
  bash --login -c "
    source \$(conda info --base)/etc/profile.d/conda.sh
    conda activate ubp
    cd /mnt/tdmpc2
    export MUJOCO_GL=disable
    python3 ${TEST_FILE}
"