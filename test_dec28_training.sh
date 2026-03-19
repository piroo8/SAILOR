#!/bin/bash
#SBATCH --job-name=6_dec_28int
#SBATCH --output=/home/ishakpie/projects/def-rhinehar/ishakpie/logs/sailor_%j.out
#SBATCH --error=/home/ishakpie/projects/def-rhinehar/ishakpie/logs/sailor_%j.err
#SBATCH --time=6:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --gres=gpu:nvidia_h100_80gb_hbm3_3g.40gb:1
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

    export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True

    export MUJOCO_GL=osmesa

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
    export WANDB_MODE=disabled

    cd /SAILOR
    SUITE=robomimic
    TASK=lift
    NUM_EXP_TRAJS=5
    SEED=2

    python3 train_sailor.py \
      --configs cfg_dp_mppi "$SUITE" \
      --wandb_project "SAILOR_${SUITE}" \
      --wandb_exp_name "local_test" \
      --task "${SUITE}__${TASK}" \
      --num_exp_trajs "$NUM_EXP_TRAJS" \
      --seed "$SEED"
  '
