#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
export CUDA_ARCH=compute_35

mkdir -p results

CORR=results/lab5_correctness.log
PERF=results/lab5_performance.log

: > "$CORR"
: > "$PERF"

run_group() {
    local mode="$1"
    local tile="$2"
    local log="$3"
    shift 3

    {
        echo "========== METHOD=$mode TILE_WIDTH=$tile =========="

        CUDA_ARCH="$CUDA_ARCH" bash compile.sh "$mode" "$tile"

        for n in "$@"; do
            echo "----- N=$n MODE=$mode TILE_WIDTH=$tile -----"
            ./a.out 1 "$n"
        done
    } 2>&1 | tee -a "$log"
}

echo "========== LAB5 CORRECTNESS TESTS =========="

# Shared Memory: all three tile widths
for tile in 8 16 32; do
    run_group lab5 "$tile" "$CORR" \
        1 7 16 17 31 32 33 65 1000
done

# cuBLAS: TILE_WIDTH does not control its GEMM tiling
run_group cublas 16 "$CORR" \
    1 7 16 17 31 32 33 65 1000

echo "========== LAB5 PERFORMANCE TESTS =========="

# Shared Memory: 12 configurations
for tile in 8 16 32; do
    run_group lab5 "$tile" "$PERF" \
        256 512 1000 1024
done

# cuBLAS: 4 matrix sizes
run_group cublas 16 "$PERF" \
    256 512 1000 1024

echo "========== TEST SUMMARY =========="

echo "Correctness zero-error count:"
grep -c 'Total Errors = 0' "$CORR"

echo "Performance zero-error count:"
grep -c 'Total Errors = 0' "$PERF"

echo "Lab5 tests completed successfully."
