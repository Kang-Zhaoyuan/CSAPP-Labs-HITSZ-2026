#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
for tile in 8 16 32; do
  for mode in lab4 lab5 cublas; do
    bash compile.sh "$mode" "$tile"
    for size in 1 7 16 17 31 32 33 65 1000; do
      ./a.out 1 "$size"
    done
  done
done
echo 'All GPU checks passed.'
