# CUDA 矩阵乘法

`matrix_mul_lab4.cu` 是全局内存基线；`matrix_mul_lab5.cu` 使用共享内存分块，定义 `USE_CUBLAS` 时调用 `cublasSgemm`。

```bash
cd labs/lab4-5
bash compile.sh lab4 16
./a.out 1 1000
bash compile.sh lab5 16
./a.out 1 1000
bash compile.sh cublas 16
./a.out 1 1000
```

参数为 `./a.out <check: 0|1> <matrix_size>`。通过 `CUDA_ARCH=compute_XX` 指定目标 GPU；默认交给 nvcc 选择。

`bash test.sh` 验证边界尺寸；`bash benchmark.sh` 扫描共享内存与 cuBLAS 配置，输出至 `build/measurements/`。该评测脚本默认 `compute_35`，可通过 `CUDA_ARCH` 覆盖。

[正式数据](results/) · [Lab4 指导书](../../docs/实验4/) · [Lab5 指导书](../../docs/实验5/)
