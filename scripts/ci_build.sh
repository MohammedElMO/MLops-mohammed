#!/usr/bin/env bash
set -euo pipefail

export GITHUB_USERNAME="${GITHUB_USERNAME:-ci}"
export EFS_DIR="${EFS_DIR:-$PWD/efs}"
export RAY_TMPDIR="${RAY_TMPDIR:-/tmp/ray_mlopsfull_ci_build}"
export RAY_DEDUP_LOGS="${RAY_DEDUP_LOGS:-0}"
export TOKENIZERS_PARALLELISM="${TOKENIZERS_PARALLELISM:-false}"

mkdir -p results "$EFS_DIR" "$RAY_TMPDIR"

python -m pip check
python -c "from madewithml import config, data, models, train, utils; print('imports ok')"
python -c "from madewithml.config import logger; logger.info('ci build logging test'); print('logging ok')"

python -m madewithml.train \
  --experiment-name ci-build \
  --dataset-loc datasets/dataset.csv \
  --train-loop-config '{"dropout_p":0.5,"lr":0.0001,"lr_factor":0.8,"lr_patience":3}' \
  --num-workers 1 \
  --cpu-per-worker 1 \
  --gpu-per-worker 0 \
  --num-samples 32 \
  --num-epochs 1 \
  --batch-size 8 \
  --results-fp results/ci_build_results.json
