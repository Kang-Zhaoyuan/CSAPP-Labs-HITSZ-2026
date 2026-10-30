# Lab 6: Llama 推理与矩阵乘法优化

保留原始标量推理为 Baseline，并实现 AVX2 + OpenMP 向量化内核（`run-opt`）。内核按 8 输出行并行分组，单 lane 累加顺序与标量严格一致，配置 `-ffp-contract=off` 以保证逐位无误差（Bitwise Identical）。

## 1. 运行时矩阵尺寸映射

通过 `-DMATMUL_TRACE` 捕获运行时唯一执行的 $W_{d \times n} \cdot x_n \to y_d$ 维度：

| 权重矩阵 | 输出 $d$ | 输入 $n$ | 物理含义 |
|---|---:|---:|---|
| $W_q$、$W_o$ | `dim` | `dim` | 注意力 Query / Output 投影 |
| $W_k$、$W_v$ | `kv_dim` | `dim` | 注意力 Key / Value 投影（含 GQA） |
| $W_1$、$W_3$ | `hidden_dim` | `dim` | SwiGLU 升维门控与值投影 |
| $W_2$ | `dim` | `hidden_dim` | SwiGLU 降维投影 |
| $W_{cls}$ | `vocab_size` | `dim` | 输出词表分类头 |

注：`kv_dim = dim * n_kv_heads / n_heads`。

## 2. 评测接口与产物

- 构建目标：`make run`（基线）、`make runopt`（AVX2+OpenMP）、`make testmatmul`（逐位单测）。
- 吞吐压测：`python3 benchmark.py --runs 3 --steps 256 --threads 8`（输出 `benchmark_results.csv`）。
- 瓶颈分析：`bash profile.sh <model.bin>`（生成 `perf.svg` 与 `perf.report.txt`）。
- 实测归档：全规格性能数据与 110M 火焰图详见 [`results/README.md`](results/README.md)。
