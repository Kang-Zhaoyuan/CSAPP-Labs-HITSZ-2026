# Llama 推理优化

基于 [karpathy/llama2.c](https://github.com/karpathy/llama2.c)，上游代码保留 [MIT 许可证](LICENSE)。

优化内核按 8 个输出行使用 AVX2，并用 OpenMP 分配输出行。每个输出的累加顺序与标量一致；`-ffp-contract=off` 禁止融合乘加，避免改变逐位结果。不要为逐位对比启用 fast-math 或 FMA。

```bash
cd labs/lab6
python3 download_models.py
make run runopt testmatmul
python3 benchmark.py --runs 5 --steps 256 --threads 8
```

模型下载需要校园网；`stories*.bin` 不进入版本管理。评测比较生成文本，并将逐轮吞吐与输出 SHA-256 写入 `build/benchmark_results.csv`。

```bash
make runtrace
./run-trace stories15M.bin -n 32 -t 0.0 -s 42
bash profile.sh stories110M.bin 256
```

`runtrace` 记录唯一矩阵尺寸。性能分析需 Linux perf、PMU 与 FlameGraph；通过 `FLAMEGRAPH_DIR` 指定脚本目录，采样频率由 `PERF_FREQ` 控制，产物位于 `build/profile/`。

矩阵向量乘法为 $W_{d\times n}x_n=y_d$：注意力投影使用 `dim` / `kv_dim`，SwiGLU 升降维使用 `hidden_dim`，分类头输出 `vocab_size`；`kv_dim = dim * n_kv_heads / n_heads`。

[正式结果](results/) · [完整指导书](../../docs/实验6/)
