#!/usr/bin/env python3
"""Compare scalar Baseline and AVX2/OpenMP Llama inference throughput."""

import argparse
import csv
import hashlib
import os
from pathlib import Path
import re
import statistics
import subprocess
import sys

HERE = Path(__file__).resolve().parent
DEFAULT_MODELS = ("stories15M.bin", "stories42M.bin", "stories110M.bin")
RATE_RE = re.compile(rb"achieved tok/s:\\s*([0-9]+(?:\\.[0-9]+)?(?:[eE][+-]?\\d+)?)")


def run_once(binary, model, args, env):
    command = [
        str(binary), str(model),
        "-n", str(args.steps),
        "-t", str(args.temperature),
        "-p", "0",
        "-s", str(args.seed),
    ]
    if args.prompt is not None:
        command.extend(["-i", args.prompt])

    result = subprocess.run(command, cwd=HERE, env=env, capture_output=True, check=True)
    match = RATE_RE.search(result.stderr)
    if not match:
        detail = result.stderr.decode("utf-8", errors="replace")
        raise RuntimeError(f"{binary.name} did not report tok/s for {model.name}:\\n{detail}")
    rate = float(match.group(1))
    digest = hashlib.sha256(result.stdout).hexdigest()
    return rate, result.stdout, digest


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("models", nargs="*", help="model files in labs/lab6 (default: all three)")
    parser.add_argument("--runs", type=int, default=3, help="repetitions per model (default: 3)")
    parser.add_argument("--steps", type=int, default=256, help="generation steps (default: 256)")
    parser.add_argument("--seed", type=int, default=42, help="fixed sampler seed (default: 42)")
    parser.add_argument("--temperature", type=float, default=0.0,
                        help="0.0 uses greedy decoding for reproducible text comparison")
    parser.add_argument("--prompt", default=None, help="optional fixed prompt")
    parser.add_argument("--threads", type=int, default=min(8, os.cpu_count() or 1),
                        help="OpenMP threads for the optimized build")
    parser.add_argument("--output", default="benchmark_results.csv", help="CSV output path")
    parser.add_argument("--no-build", action="store_true", help="use existing run and run-opt binaries")
    args = parser.parse_args()

    if args.runs < 1 or args.steps < 2 or args.threads < 1:
        parser.error("--runs and --threads must be positive, and --steps must be at least 2")

    model_names = args.models or list(DEFAULT_MODELS)
    models = [Path(name) if Path(name).is_absolute() else HERE / name for name in model_names]
    missing = [model.name for model in models if not model.is_file()]
    if missing:
        parser.error("missing model file(s): " + ", ".join(missing) +
                     ". Download them with: python3 download_models.py " + " ".join(missing))

    baseline = HERE / "run"
    optimized = HERE / "run-opt"
    if not args.no_build:
        subprocess.run(["make", "run", "runopt"], cwd=HERE, check=True)
    for binary in (baseline, optimized):
        if not binary.is_file():
            parser.error(f"missing executable {binary.name}; run make run and make runopt")

    env = os.environ.copy()
    env["OMP_NUM_THREADS"] = str(args.threads)

    rows = []
    summaries = []
    for model in models:
        baseline_rates = []
        optimized_rates = []
        for repeat in range(1, args.runs + 1):
            base_rate, base_text, base_hash = run_once(baseline, model, args, env)
            opt_rate, opt_text, opt_hash = run_once(optimized, model, args, env)
            if base_text != opt_text:
                raise RuntimeError(
                    f"generated text differs for {model.name}, run {repeat}; "
                    f"baseline sha256={base_hash}, optimized sha256={opt_hash}"
                )
            baseline_rates.append(base_rate)
            optimized_rates.append(opt_rate)
            rows.append({
                "model": model.name,
                "repeat": repeat,
                "baseline_tok_s": f"{base_rate:.6f}",
                "optimized_tok_s": f"{opt_rate:.6f}",
                "speedup": f"{opt_rate / base_rate:.6f}",
                "output_sha256": base_hash,
            })
            print(f"{model.name} run {repeat}/{args.runs}: "
                  f"Baseline {base_rate:.2f} tok/s, AVX2+OpenMP {opt_rate:.2f} tok/s, "
                  f"{opt_rate / base_rate:.3f}x; text identical")

        base_mean = statistics.mean(baseline_rates)
        opt_mean = statistics.mean(optimized_rates)
        speedup = opt_mean / base_mean
        summaries.append((model.name, base_mean, opt_mean, speedup))

    output = Path(args.output)
    if not output.is_absolute():
        output = HERE / output
    with output.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=[
            "model", "repeat", "baseline_tok_s", "optimized_tok_s", "speedup", "output_sha256"
        ])
        writer.writeheader()
        writer.writerows(rows)

    print("\\nReport-ready summary (mean of each variant):")
    print(f"{'Model':<20} {'Baseline tok/s':>16} {'Optimized tok/s':>17} {'Speedup':>10}")
    for name, base_mean, opt_mean, speedup in summaries:
        print(f"{name:<20} {base_mean:>16.2f} {opt_mean:>17.2f} {speedup:>9.3f}x")
    print(f"Per-run data written to {output}")


if __name__ == "__main__":
    try:
        main()
    except (OSError, subprocess.CalledProcessError, RuntimeError) as exc:
        print(f"benchmark failed: {exc}", file=sys.stderr)
        sys.exit(1)
