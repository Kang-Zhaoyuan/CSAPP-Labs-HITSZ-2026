# Llama 实测结果

| 模型 | 标量 tok/s | AVX2 + OpenMP tok/s | 加速比 |
|---|---:|---:|---:|
| stories15M | 82.74 | 529.16 | 6.396× |
| stories42M | 27.70 | 205.42 | 7.416× |
| stories110M | 10.49 | 76.98 | 7.337× |

每个模型 5 轮，表中为两种实现的吞吐均值及其比值。[逐轮数据](benchmark_formal.csv) 包含输出文本 SHA-256；[权重校验和](model_checksums.sha256) 标识三个模型文件。

实验条件：2026-10-30，源码提交 `58a0ac66ffbfc879a75c89edf78a66def3a368d3`；Intel Core i7-10700（8 核 16 线程），Ubuntu 20.04 / Linux 5.8.0-43，GCC 9.4.0。优化版使用 8 个 OpenMP 线程、`-O3 -mavx2 -fopenmp -ffp-contract=off`；256 步，temperature=0、seed=42。

| 模型 | 实际执行的权重矩阵尺寸 |
|---|---|
| stories15M | 288×288、768×288、288×768、32000×288 |
| stories42M | 512×512、1376×512、512×1376、32000×512 |
| stories110M | 768×768、2048×768、768×2048、32000×768 |

110M 标量基线的 cycles 采样频率为 99 Hz，`matmul` 占采样事件的 97.95%；见[性能报告](perf_110M_report.txt)与[火焰图](flamegraph_110M.svg)。

重新构建与评测见[运行说明](../README.md)。
