# 实测数据

## 1. 吞吐测试

Baseline 为标量 `run`，优化版为 AVX2 + OpenMP `run-opt`（内核设计见 [OPTIMIZATION.md](../OPTIMIZATION.md)）。

| Checkpoint | Baseline (tok/s) | AVX2 + OpenMP (tok/s) | Speedup |
|---|---:|---:|---:|
| stories15M | 82.74 | 529.16 | 6.396× |
| stories42M | 27.70 | 205.42 | 7.416× |
| stories110M | 10.49 | 76.98 | 7.337× |

测试配置：8 线程，greedy decoding（`-t 0.0 -s 42`），文本哈希一致；逐次数据见 [benchmark_formal.csv](benchmark_formal.csv)。

## 2. 矩阵维度

| Checkpoint | 实际执行 $W_{d \times n}$ | 原始日志 |
|---|---|---|
| stories15M | 288×288、768×288、288×768、32000×288 | [15M 日志](matmul_shapes_stories15M.log) |
| stories42M | 512×512、1376×512、512×1376、32000×512 | [42M 日志](matmul_shapes_stories42M.log) |
| stories110M | 768×768、2048×768、768×2048、32000×768 | [110M 日志](matmul_shapes_stories110M.log) |

## 3. 热点分析

110M 基线在 99 Hz 采样下 `matmul` 周期占比 97.95%，验证为主要瓶颈；产物见 [火焰图](flamegraph_110M.svg) 与 [perf 报告](perf_110M_report.txt)。

## 4. 环境说明

完整测试环境与软硬件配置记录见 [experiment_environment.txt](experiment_environment.txt)。

## 5. 文件映射

| 归档产物 | 说明 |
|---|---|
| [`benchmark_formal.csv`](benchmark_formal.csv) / [`.log`](benchmark_formal.log) | 5 轮正式评测吞吐数据与终端记录 |
| [`benchmark_smoke.csv`](benchmark_smoke.csv) / [`.log`](benchmark_smoke.log) | 单轮冒烟测试数据与终端记录 |
| [`build_and_matmul_test.log`](build_and_matmul_test.log) | 优化编译与 12 组逐位单测通过日志 |
| [`matmul_shapes_stories*.log`](matmul_shapes_stories15M.log) | 15M / 42M / 110M 运行时矩阵尺寸捕获 |
| [`perf_110M_report.txt`](perf_110M_report.txt) / [`flamegraph_110M.svg`](flamegraph_110M.svg) | 110M 符号占比报告与 SVG 火焰图 |
| [`perf_110M.unfold`](perf_110M.unfold) / [`.folded`](perf_110M.folded) / [`.data`](perf_110M.data) | Perf 展开栈、折叠栈与原始采样文件 |
| [`experiment_environment.txt`](experiment_environment.txt) | 测试主机 CPU、内核与编译工具链详细规格 |
| [`model_checksums.sha256`](model_checksums.sha256) | 权重文件及各轮输出文本 SHA-256 校验和 |
