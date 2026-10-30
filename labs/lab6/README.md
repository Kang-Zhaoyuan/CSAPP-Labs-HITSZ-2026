# Lab 6：Llama 推理与矩阵乘法优化

保留原始标量推理为 Baseline，并实现 AVX2 + OpenMP 向量化内核（`run-opt`）。优化版按 8 个输出行分组：每个 AVX2 lane 对应一个输出元素，内层归约按原始 $j=0 \dots n-1$ 顺序执行。编译时配置 `-ffp-contract=off` 且关闭快速数学选项，严格保持单元素累加顺序与标量基线逐位一致（Bitwise Identical）。

## 1. 运行时矩阵尺寸映射

通过 `-DMATMUL_TRACE` 捕获运行时唯一执行的 $W_{d \times n} \cdot x_n \to y_d$ 维度：

| 权重矩阵 | 输出维度 $d$ | 输入维度 $n$ | 物理含义 |
|---|---:|---:|---|
| $W_q$、$W_o$ | `dim` | `dim` | Query / Output 注意力投影 |
| $W_k$、$W_v$ | `kv_dim` | `dim` | Key / Value 投影（含 GQA 映射） |
| $W_1$、$W_3$ | `hidden_dim` | `dim` | SwiGLU 升维门控与值投影 |
| $W_2$ | `dim` | `hidden_dim` | SwiGLU 降维投影 |
| $W_{cls}$ | `vocab_size` | `dim` | 输出分类头（词表维度） |

其中 `kv_dim = dim * n_kv_heads / n_heads`。

## 2. 构建与回归测试

```bash
make run                 # 标量基线
make runopt              # AVX2 + OpenMP 优化版本
make testmatmul          # 与标量参考执行 memcmp 逐位回归比对（覆盖非对齐与残差维度）
```

单测对随机输入执行严格的 `memcmp` 二进制核验；端到端模型推理在贪心解码下比较输出文本字节流与 SHA-256 哈希。

## 3. 性能基准与分析脚本

- **多模型自动化压测**：
  ```bash
  python3 benchmark.py --runs 3 --steps 256 --threads 8
  ```
  自动化构建并运行各规模模型（15M / 42M / 110M），记录 Baseline 与优化版本的平均 `tok/s`、加速比及输出文本哈希，输出数据至 `benchmark_results.csv`。
- **PMU 热点采样与火焰图**：
  ```bash
  bash profile.sh stories15M.bin 256
  ```
  使用保留帧指针与符号表的构建版本（`run-profile`）进行硬件事件采样，生成 `perf.data`、`perf.svg` 火焰图与符号热点报告 `perf.report.txt`。

## 4. 实测产物

物理机实测数据统一归档于 [`results/`](results/) 目录，包含全规格性能测试 CSV、环境信息、矩阵尺寸日志与 110M 完整 FlameGraph。测试配置与分析详见 [`results/README.md`](results/README.md)。
