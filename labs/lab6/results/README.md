# Lab 6 实测结果

实验日期：2026-10-30。

## 推理性能

Baseline 为标量 `run`，优化版为 AVX2 + OpenMP `run-opt`；内核实现见 [OPTIMIZATION.md](../OPTIMIZATION.md)。

| Checkpoint | Baseline (tok/s) | AVX2 + OpenMP (tok/s) | Speedup |
|---|---:|---:|---:|
| stories15M | 82.74 | 529.16 | 6.396× |
| stories42M | 27.70 | 205.42 | 7.416× |
| stories110M | 10.49 | 76.98 | 7.337× |

每个模型重复 5 次，`-n 256`；优化版使用 8 个 OpenMP 线程。固定参数为 seed 42、temperature 0.0、top-p 0.0（greedy decoding）。每次测试均逐字节比较两种实现的标准输出；同一模型的 5 次输出 SHA-256 相同。逐次数据见 [benchmark_formal.csv](benchmark_formal.csv)。

## 矩阵尺寸

运行时记录到的矩阵乘法形状为 (W(d×n) · x(n) → y(d))：

| Checkpoint | 实际出现的 (W(d×n)) |
|---|---|
| stories15M | 288×288、768×288、288×768、32000×288 |
| stories42M | 512×512、1376×512、512×1376、32000×512 |
| stories110M | 768×768、2048×768、768×2048、32000×768 |

完整记录：[15M](matmul_shapes_stories15M.log) · [42M](matmul_shapes_stories42M.log) · [110M](matmul_shapes_stories110M.log)。

## 110M 性能采样

对 110M Baseline 进行 99 Hz call-graph 采样，执行 `-n 256`。约 2K 个 cycles 样本中，`matmul` 占 97.95%，`forward` 占 1.17%；报告记录的 lost samples 为 0。该结果将矩阵乘法定位为本次工作负载的主要 CPU 热点；它不包含 cache-miss 或内存带宽测量。

采样产物：[perf 报告](perf_110M_report.txt) · [原始 perf.data](perf_110M.data) · [火焰图](flamegraph_110M.svg)。

## 环境与复现

测试环境为 Linux 5.8.0-43-generic、Intel Core i7-10700（8 核 16 线程）、GCC 9.4.0，CPU 支持 AVX2。完整环境记录见 [experiment_environment.txt](experiment_environment.txt)。吞吐率仅适用于该环境及上述参数。

模型权重来自 [karpathy/tinyllamas](https://huggingface.co/karpathy/tinyllamas)，未纳入仓库。在本目录下载权重并复现：

```bash
python3 download_models.py stories15M.bin stories42M.bin stories110M.bin
python3 benchmark.py stories15M.bin stories42M.bin stories110M.bin \
  --runs 5 --steps 256 --threads 8 --seed 42 \
  --temperature 0.0 --output results/benchmark_formal.csv
```
