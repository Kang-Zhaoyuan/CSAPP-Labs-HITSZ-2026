# Lab 4 & 5: CUDA 矩阵乘法

- `matrix_mul_lab4.cu`: 全局内存基线内核（单线程计算单元素）。
- `matrix_mul_lab5.cu`: 共享内存分块优化内核；宏 `USE_CUBLAS` 切换至 `cublasSgemm`。
- `compile.sh`: `bash compile.sh [lab4|lab5|cublas] [tile_width]` 生成 `a.out`（可通过环境变量 `CUDA_ARCH=compute_XX` 覆盖目标架构）。
- `test.sh`: 覆盖非对齐尺寸与边界残差的正确性测试套件。
- `results/`: 包含物理机实测日志、正确性验证输出与性能对比数据（CSV）。

执行格式：`./a.out <check: 0|1> <matrix_size>`
