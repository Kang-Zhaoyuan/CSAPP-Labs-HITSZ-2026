# 计算机体系结构实验

哈尔滨工业大学（深圳）2026 秋季课程实验。

| 实验 | 实现 | 指导书 / 结果 |
|---|---|---|
| [Lab1](labs/lab1/) | x87 矩阵乘法、AVX2/FMA | [指导书](docs/实验1/) |
| [Lab2](labs/lab2/) | 软件预取、循环重排、32×32 分块 | [指导书](docs/实验2/) |
| [Lab3](labs/lab3/) | 循环展开、AVX 分块、OpenMP | [运行说明](labs/lab3/) · [指导书](docs/实验3/) |
| [Lab4–5](labs/lab4-5/) | CUDA、共享内存、cuBLAS | [正式数据](labs/lab4-5/results/) · [Lab4 指导书](docs/实验4/) · [Lab5 指导书](docs/实验5/) |
| [Lab6](labs/lab6/) | Llama AVX2 + OpenMP 推理 | [正式结果](labs/lab6/results/) · [指导书](docs/实验6/) |

Lab1–3 需要 Linux x86-64、GCC/G++、CMake、AVX2/FMA 和 OpenMP。将下列 `lab3` 换成对应实验：

```bash
cmake -S labs/lab3 -B labs/lab3/build -DCMAKE_BUILD_TYPE=Release
cmake --build labs/lab3/build --parallel
ctest --test-dir labs/lab3/build --output-on-failure --no-tests=error
```

GPU 与 Llama 的编译、评测入口见各实验说明。正式数据保存在 `results/`，临时评测产物写入忽略的 `build/`。
