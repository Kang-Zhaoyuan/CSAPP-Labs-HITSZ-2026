# Lab4 / Lab5：CUDA 矩阵乘法

在带 NVIDIA GPU、驱动和 CUDA Toolkit（含 nvcc、cuBLAS）的 Ubuntu 机器上执行。

```bash
cd labs/lab4-5
nvidia-smi
nvcc --version

bash compile.sh lab4 16
./a.out 1 1000
bash compile.sh lab5 16
./a.out 1 1000
bash compile.sh cublas 16
./a.out 1 1000
```

- `matrix_mul_lab4.cu`：每个线程计算一个结果元素。
- `matrix_mul_lab5.cu`：共享内存分块；定义 `USE_CUBLAS` 时改用 `cublasSgemm`。
- `matrix_mul.cu`：保留旧入口，默认运行 Lab4。
- `compile.sh`：第一个参数选择版本，第二个参数为线程块边长，默认 `lab4 16`，输出 `a.out`。每次编译覆盖上一个可执行文件。
- `./a.out <check> <size>`：`check=1` 与 CPU 结果比较；`check=0` 跳过校验。成功校验输出 `Total Errors = 0`，CUDA 错误或结果错误返回非零退出码。

默认使用 nvcc 的目标架构；需要指定显卡架构时，例如：

```bash
CUDA_ARCH=compute_75 bash compile.sh lab5 16
```

请按目标显卡和 Toolkit 支持情况调整 `compute_75`。

## 正确性检查

```bash
bash test.sh
```

脚本覆盖三种实现、8/16/32 的块边长，以及 1、7、16、17、31、32、33、65、1000 的矩阵边长，包含不满一个块和不能整除块大小的情况。输入使用不同的含负数序列，便于发现转置、索引和边界错误；不对结果取整。校验容差为 `1e-5 * (1 + abs(CPU结果))`。

## 报告数据

分别用 `lab4`、`lab5`、`cublas`，比较 256、512、1000、1024 等矩阵尺寸和 8、16、32 的块边长。程序先预热一次，再用 CUDA Event 测量 5 次计算的平均耗时，输出 ms 和 GFLOP/s；不包含内存分配、数据传输和 CPU 校验。cuBLAS 自行选择分块，不受本程序 `TILE_WIDTH` 控制。

建议在同一台 Ubuntu NVIDIA 机器上记录 GPU 型号、CUDA 版本、三种版本的正确性及性能输出，并保存终端截图。小矩阵耗时容易受噪声影响，可多运行几次比较；共享内存版本不保证在所有尺寸下都更快。

提交源码使用独立的 `matrix_mul_lab4.cu` 和 `matrix_mul_lab5.cu`，与指导书要求的文件名一致。

## 本机验证限制

当前开发电脑为 AMD Radeon 780M，WSL 中没有 nvcc，Docker 引擎未就绪。本机只完成代码检查和 Shell 脚本检查，尚未完成 nvcc 编译、GPU 正确性及性能测试。请在 NVIDIA Ubuntu 机器上运行上述命令后再填写报告数据。
