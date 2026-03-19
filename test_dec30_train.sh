#!/bin/bash
#SBATCH --job-name=s_run_23_5_cpu1_lift_10demos
#SBATCH --output=/home/ishakpie/projects/def-rhinehar/ishakpie/logs/sailor_%j.out
#SBATCH --error=/home/ishakpie/projects/def-rhinehar/ishakpie/logs/sailor_%j.err
#SBATCH --time=23:30:0
#SBATCH --cpus-per-task=1
#SBATCH --mem=18G
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

    # -------------------- Persistent cache (NO INTERNET needed) --------------------
    # You already downloaded resnet18 here via download_base_dp.sh
    export XDG_CACHE_HOME=/SAILOR/.cache
    export TORCH_HOME=/SAILOR/.cache/torch
    mkdir -p "$TORCH_HOME/hub/checkpoints" "$XDG_CACHE_HOME"

    # -------------------- Temp dirs for other libs --------------------
    export HOME=/tmp/home
    export MPLCONFIGDIR=/tmp/mplconfig
    export FC_CACHEDIR=/tmp/fontconfig
    export NUMBA_CACHE_DIR=/tmp/numba-cache
    export NUMBA_DISABLE_CACHING=1
    mkdir -p "$HOME" "$MPLCONFIGDIR" "$FC_CACHEDIR" "$NUMBA_CACHE_DIR"

    # Prefer conda env shared libs
    export LD_LIBRARY_PATH="$CONDA_PREFIX/lib:/opt/conda/lib:${LD_LIBRARY_PATH:-}"

    # Force correct jpeg to avoid libtiff/libjpeg ABI mismatch
    export LD_PRELOAD="$CONDA_PREFIX/lib/libjpeg.so.8:${LD_PRELOAD:-}"

    export PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True
    export MUJOCO_GL=osmesa

    # Disable wandb (you also have use_wandb=False in config, this is extra safety)
    export WANDB_MODE=disabled

    export PYTHONUNBUFFERED=1
    # -------------------- Sanity checks --------------------
    python - <<PY
import cv2
print("cv2 OK:", cv2.__version__)
PY

    python - <<PY
import os, pathlib, torch
print("torch:", torch.__version__)
print("cuda available:", torch.cuda.is_available())
print("TORCH_HOME:", os.environ.get("TORCH_HOME"))
print("torch hub dir:", torch.hub.get_dir())
ckpt = pathlib.Path(os.environ["TORCH_HOME"]) / "hub/checkpoints/resnet18-f37072fd.pth"
print("resnet18 ckpt exists:", ckpt.exists(), "path:", ckpt)
if ckpt.exists():
    print("resnet18 ckpt size:", ckpt.stat().st_size)
if torch.cuda.is_available():
    print("gpu:", torch.cuda.get_device_name(0))
PY

    # -------------------- Run training --------------------
    cd /SAILOR
    SUITE=robomimic
    TASK=lift
    NUM_EXP_TRAJS=10
    SEED=1

    python3 train_sailor.py \
      --configs cfg_dp_mppi "$SUITE" \
      --wandb_project "SAILOR_${SUITE}" \
      --wandb_exp_name "lift_10demos_23.5h_1cpu_40gb_gpu_18ram_resnetload" \
      --task "${SUITE}__${TASK}" \
      --num_exp_trajs "$NUM_EXP_TRAJS" \
      --seed "$SEED"

  '
