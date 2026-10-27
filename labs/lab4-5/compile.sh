#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
# Usage: bash compile.sh [lab4|lab5|cublas] [tile_width]
mode=${1:-lab4}
tile=${2:-16}
case "$mode" in
  lab4) source=matrix_mul_lab4.cu; extra=() ;;
  lab5) source=matrix_mul_lab5.cu; extra=() ;;
  cublas) source=matrix_mul_lab5.cu; extra=(-DUSE_CUBLAS -lcublas) ;;
  *) echo 'Usage: bash compile.sh [lab4|lab5|cublas] [tile_width]' >&2; exit 1 ;;
esac
if [[ ! "$tile" =~ ^[0-9]+$ ]] || (( tile < 1 || tile > 32 )); then
  echo 'tile_width must be 1..32' >&2
  exit 1
fi
# Override for the target GPU, e.g. CUDA_ARCH=compute_75 bash compile.sh lab5.
arch=()
if [[ -n "${CUDA_ARCH:-}" ]]; then arch=(-arch="$CUDA_ARCH"); fi
nvcc -O2 -std=c++11 "${arch[@]}" -DTILE_WIDTH="$tile" "$source" "${extra[@]}" -o a.out
