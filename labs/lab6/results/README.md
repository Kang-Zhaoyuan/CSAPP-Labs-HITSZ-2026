# Lab 6 实测结果

## 1. 推理吞吐

Baseline 为标量 `run`，优化版为 AVX2 + OpenMP `run-opt`（内核设计见 [OPTIMIZATION.md](../OPTIMIZATION.md)）。

| Checkpoint | Baseline (tok/s) | AVX2 + OpenMP (tok/s) | Speedup |
|---|---:|---:|---:|
| stories15M | 82.74 | 529.16 | 6.396× |
| stories42M | 27.70 | 205.42 | 7.416× |
| stories110M | 10.49 | 76.98 | 7.337× |

测试配置：8 线程，greedy decoding（`-t 0.0 -s 42`），文本哈希一致；逐次数据见 [benchmark_formal.csv](benchmark_formal.csv)。

## 2. 矩阵尺寸

| Checkpoint | 实际执行 $W_{d \times n}$ | 原始日志 |
|---|---|---|
| stories15M | 288×288、768×288、288×768、32000×288 | [15M 日志](matmul_shapes_stories15M.log) |
| stories42M | 512×512、1376×512、512×1376、32000×512 | [42M 日志](matmul_shapes_stories42M.log) |
| stories110M | 768×768、2048×768、768×2048、32000×768 | [110M 日志](matmul_shapes_stories110M.log) |

## 3. 性能热点采样

110M 基线在 99 Hz 采样下 `matmul` 周期占比 97.95%，验证为主要瓶颈；产物见 [火焰图](flamegraph_110M.svg) 与 [perf 报告](perf_110M_report.txt)。

## 4. 测试环境

完整测试环境与软硬件配置记录见 [experiment_environment.txt](experiment_environment.txt)。
