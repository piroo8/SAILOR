module load apptainer
SIF_PATH=/home/ishakpie/projects/def-rhinehar/ishakpie/opt_robo_cu128_cvfix.sif
CACHE_DIR=/home/ishakpie/projects/def-rhinehar/ishakpie/Sailor/.cache

mkdir -p $CACHE_DIR/torch/hub/checkpoints

apptainer exec --nv \
  --no-home \
  --fakeroot \
  --contain \
  --bind /home/ishakpie/projects/def-rhinehar/ishakpie/Sailor:/SAILOR \
  "$SIF_PATH" \
  bash -lc "
    source /opt/conda/etc/profile.d/conda.sh
    conda activate robo

    export XDG_CACHE_HOME=/SAILOR/.cache
    export TORCH_HOME=/SAILOR/.cache/torch

    python - <<'PY'
import torch
from torchvision.models import resnet18, ResNet18_Weights
m = resnet18(weights=ResNet18_Weights.DEFAULT)
print('torch hub dir:', torch.hub.get_dir())
PY
  "
