# 计算机体系结构实验（CSAPP / Architecture Labs）

哈尔滨工业大学（深圳）计算机体系结构课程实验工程。

## 目录结构

- `lab1/` - 实验一：浮点矩阵乘法与 SIMD 向量化
- `lab2/` - 实验二：存储层次与 Cache 优化
- `lab3/` - 实验三：指令级并行与 OpenMP 多线程优化
- `docs/` - 实验指导书与实验报告模板

## 构建与测试

各 `lab*` 均为独立的 CMake 工程，依赖 Linux x86-64 环境（需支持 AVX2、FMA 指令集扩展及 OpenMP）。

```bash
cd <lab-dir>
cmake -B build
cmake --build build
ctest --test-dir build --output-on-failure
```

实验指导书详见 [`docs/README.md`](docs/README.md)。
