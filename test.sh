#!/bin/bash
SIF_PATH=/home/ishakpie/projects/def-rhinehar/ishakpie/Sailor/py_2_6_cuda_12_4_cudn_9_devel.sif
SCRIPT_PATH=/Sailor

module load apptainer

apptainer exec --nv \
  --no-home \
  --fakeroot \
  --contain \
  --bind /home/ishakpie/projects/def-rhinehar/ishakpie/Sailor:/SAILOR \
  "$SIF_PATH" \
  bash --login -c "
    source /root/anaconda3/bin/activate
    conda activate rob
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
"