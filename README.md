# 计算机体系结构实验（CSAPP / Architecture Labs）

哈尔滨工业大学（深圳）计算机体系结构课程实验仓库。

## 仓库目录树

```text
.
├── labs/
│   ├── lab1/              # 实验1：x87 浮点矩阵乘法与 AVX2/FMA 向量化
│   ├── lab2/              # 实验2：Cache 软件预取、循环重排与 32x32 分块
│   ├── lab3/              # 实验3：x87 循环展开扫描、AVX 64x64 分块与 OpenMP
│   └── lab4-5/            # 实验4~5：CUDA 矩阵乘法与 Shared Memory 分块优化
└── docs/
    ├── 00_课程总览/       # 课程大纲、作业提交说明与 x86-64 参考手册
    ├── 实验1/ ~ 实验5/    # 各实验离线指导书（Markdown / PDF / 配图）
    ├── templates/         # 官方空白实验报告模板
    ├── README.md          # 指导书索引
    └── sync_docs.py       # 指导书与模板增量同步脚本
```

## 构建与测试

- `labs/lab1` ~ `labs/lab3`（Linux x86-64，需支持 AVX2/FMA 与 OpenMP）：
  ```bash
  cmake -S labs/<lab-name> -B labs/<lab-name>/build -DCMAKE_BUILD_TYPE=Release
  cmake --build labs/<lab-name>/build
  ctest --test-dir labs/<lab-name>/build --output-on-failure
  ```
- `labs/lab4-5`（Ubuntu + NVIDIA CUDA 环境，详见 [运行说明](labs/lab4-5/README.md)）：
  ```bash
  cd labs/lab4-5 && bash compile.sh && ./a.out 1 1000
  ```

实验指导书详见 [`docs/README.md`](docs/README.md)。
