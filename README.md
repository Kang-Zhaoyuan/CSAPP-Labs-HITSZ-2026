# 计算机体系结构实验（CSAPP / Architecture Labs）

哈尔滨工业大学（深圳）计算机体系结构课程实验仓库。

## 目录结构

```text
.
├── labs/
│   ├── lab1/              # 实验1：x87 浮点矩阵乘法与 AVX2/FMA 向量化
│   ├── lab2/              # 实验2：Cache 软件预取、循环重排与 32x32 分块
│   ├── lab3/              # 实验3：x87 循环展开扫描、AVX 64x64 分块与 OpenMP
│   ├── lab4-5/            # 实验4~5：CUDA 矩阵乘法与 Shared Memory 分块优化
│   └── lab6/              # 实验6：Llama2 模型推理性能评测与矩阵乘法优化
└── docs/
    ├── 00_课程总览/       # 课程大纲、作业提交说明与 x86-64 参考手册
    ├── 实验1/ ~ 实验6/    # 各实验离线指导书（Markdown / PDF / 配图）
    ├── templates/         # 官方空白实验报告模板
    ├── README.md          # 指导书索引
    └── sync_docs.py       # 指导书与模板增量同步脚本
```

## 各模块构建与评测

- **Lab 1 ~ 3（CPU 优化）**：标准 CMake 工程，需支持 AVX2、FMA 与 OpenMP。
  ```bash
  cmake -S labs/<lab> -B labs/<lab>/build -DCMAKE_BUILD_TYPE=Release
  cmake --build labs/<lab>/build
  ctest --test-dir labs/<lab>/build --output-on-failure
  ```
- **Lab 4 ~ 5（GPU 优化）**：CUDA 矩阵乘法与共享内存优化，详见 [`labs/lab4-5/README.md`](labs/lab4-5/README.md)。
  ```bash
  cd labs/lab4-5 && bash compile.sh lab5 16 && ./a.out 1 1000
  ```
- **Lab 6（Llama 模型推理优化）**：AVX2 + OpenMP 向量化 GEMV，详见 [`labs/lab6/README.md`](labs/lab6/README.md)。
  ```bash
  cd labs/lab6 && make runopt && python3 benchmark.py --runs 3 --steps 256
  ```

实验指导书导航详见 [`docs/README.md`](docs/README.md)。
