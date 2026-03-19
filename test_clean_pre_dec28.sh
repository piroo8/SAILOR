#!/bin/bash
#SBATCH --job-name=pre_square_2h
#SBATCH --output=/home/ishakpie/projects/def-rhinehar/ishakpie/logs/sailor_%j.out
#SBATCH --error=/home/ishakpie/projects/def-rhinehar/ishakpie/logs/sailor_%j.err
#SBATCH --time=2:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --account=def-rhinehar
#SBATCH --mail-user=pierreishak2003@gmail.com
#SBATCH --mail-type=BEGIN,END,FAIL

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
    #export XDG_CACHE_HOME=/tmp/xdg-cache
    #export MPLCONFIGDIR=/tmp/mplconfig
    #export FC_CACHEDIR=/tmp/fontconfig
    #export NUMBA_CACHE_DIR=/tmp/numba-cache
    #export NUMBA_DISABLE_CACHING=1
    #mkdir -p "$HOME" 
    # need for writable cache directories numba, and matplotlib etc

    # Prefer conda env shared libs
    #export LD_LIBRARY_PATH="$CONDA_PREFIX/lib:/opt/conda/lib:${LD_LIBRARY_PATH:-}"

    # Force correct jpeg to avoid libtiff/libjpeg ABI mismatch
    export LD_PRELOAD="$CONDA_PREFIX/lib/libjpeg.so.8:${LD_PRELOAD:-}"

    export MUJOCO_GL=osmesa
   
    # Run the real command
    cd /SAILOR
    #Change file below like task, hardcoding now
    python3 -m robomimic.scripts.dataset_states_to_obs \
      --done_mode 1 \
      --dataset datasets/robomimic_datasets/square/ph/demo_v141.hdf5 \
      --output_name image_64_shaped_done1_v141.hdf5 \
      --camera_names agentview robot0_eye_in_hand \
      --camera_height 64 \
      --camera_width 64 \
      --shaped
  '
