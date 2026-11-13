#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

if [[ $# -lt 1 || $# -gt 2 ]]; then
    echo "Usage: $0 <model.bin> [steps]" >&2
    exit 2
fi

MODEL="$1"
STEPS="${2:-256}"
PERF_FREQ="${PERF_FREQ:-100}"
FLAMEGRAPH_DIR="${FLAMEGRAPH_DIR:-/usr/bin/flamegraph}"

if [[ ! -f "$MODEL" ]]; then
    echo "Model file not found: $MODEL" >&2
    exit 1
fi
if ! command -v perf >/dev/null 2>&1; then
    echo "perf is required; run this on a Linux host with PMU/perf support." >&2
    exit 1
fi
if [[ ! -x "$FLAMEGRAPH_DIR/stackcollapse-perf.pl" || ! -x "$FLAMEGRAPH_DIR/flamegraph.pl" ]]; then
    echo "FlameGraph scripts not found under $FLAMEGRAPH_DIR." >&2
    echo "Set FLAMEGRAPH_DIR to the directory containing stackcollapse-perf.pl and flamegraph.pl." >&2
    exit 1
fi

output_dir="${PROFILE_OUTPUT_DIR:-build/profile}"
mkdir -p "$output_dir"

make runprofile
perf record -o "$output_dir/perf.data" -F "$PERF_FREQ" -g -- ./run-profile "$MODEL" -n "$STEPS" -t 0.0 -s 42
perf script -i "$output_dir/perf.data" > "$output_dir/perf.unfold"
"$FLAMEGRAPH_DIR/stackcollapse-perf.pl" "$output_dir/perf.unfold" > "$output_dir/perf.folded"
"$FLAMEGRAPH_DIR/flamegraph.pl" "$output_dir/perf.folded" > "$output_dir/perf.svg"
perf report -i "$output_dir/perf.data" --stdio --no-children --sort symbol > "$output_dir/perf.report.txt"

echo "Profile written to $output_dir"
