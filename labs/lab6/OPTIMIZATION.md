# Lab 6：Llama 推理与矩阵乘法优化

本目录保留原始 run 作为 Baseline，并提供 AVX2 + OpenMP 的 run-opt。优化版按 8 个输出行分组：每个 AVX2 lane 对应一个输出元素，内层归约仍按原始 j=0..n-1 顺序执行。编译时关闭浮点收缩，不启用 -ffast-math，以保持每个输出元素的浮点累加顺序。

## 1. 查看矩阵尺寸

~~~bash
make runtrace
./run-trace stories15M.bin -n 32 -t 0.0 -s 42 2> matmul_shapes.log
cat matmul_shapes.log
~~~

日志会列出实际执行中出现的每一种 W(d x n) * x(n) -> y(d) 尺寸。按模型配置，矩阵调用对应关系为：

| 权重 | 输出维度 d | 输入维度 n |
|---|---:|---:|
| Wq、Wo | dim | dim |
| Wk、Wv | kv_dim | dim |
| W1、W3 | hidden_dim | dim |
| W2 | dim | hidden_dim |
| Wcls | vocab_size | dim |

其中 kv_dim = dim * n_kv_heads / n_heads。实际数值以每个 checkpoint 的运行时输出为准。

## 2. 编译与正确性检查

~~~bash
make run                 # 原始 Baseline
make runopt              # AVX2 + OpenMP
make testmatmul          # 与标量参考逐位比较，覆盖 SIMD 和尾部尺寸
OMP_NUM_THREADS=8 ./run-opt stories15M.bin -n 256 -t 0.0 -s 42
~~~

优化版不使用 FMA 或快速数学选项。测试程序对矩阵乘法输出执行逐位比较；完整模型测试还会比较 Baseline 和优化版的生成文本字节，任何差异都会使脚本报错。

## 3. 三种模型的性能对比

先按需下载模型权重（权重文件已被根目录 .gitignore 排除）：

~~~bash
python3 download_models.py stories15M.bin stories42M.bin stories110M.bin
~~~

执行三次重复测试：

~~~bash
python3 benchmark.py --runs 3 --steps 256 --threads 8
~~~

也可以只测某个模型，或增加重复次数：

~~~bash
python3 benchmark.py stories15M.bin --runs 5 --steps 256 --threads 8
~~~

脚本会自动构建 Baseline 和优化版，使用固定参数进行贪心解码，逐次核对输出文本，并生成 benchmark_results.csv。终端汇总表提供 Baseline 平均 tok/s、优化版平均 tok/s 和加速比，可直接整理到实验报告。

## 4. perf 与火焰图

在支持硬件性能计数器的独立 Linux 环境中执行：

~~~bash
bash profile.sh stories15M.bin 256
~~~

脚本使用带调试符号和 frame pointer 的 Baseline 构建，采集 perf.data，生成 perf.svg 火焰图及 perf.report.txt 符号占比报告。默认从 /usr/bin/flamegraph 查找 FlameGraph 脚本，也可通过 FLAMEGRAPH_DIR 指定目录。

perf 数据会受虚拟机、WSL、容器权限和 PMU 访问能力影响。正式报告应记录实际测试机器、CPU、线程数及工具版本，并在支持 PMU 的 Linux 环境采集。

## 5. 产物

benchmark_results.csv、perf.data*、perf.svg、perf.report.txt 和本目录下的编译产物均为本地生成文件，不应提交到 Git。
