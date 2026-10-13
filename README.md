# 计算机体系结构实验（Computer Architecture Labs）

哈尔滨工业大学（深圳）计算机体系结构课程实验实现，主要围绕 x86-64 架构下的单精度通用矩阵乘法（GEMM）进行层次化性能优化。

---

## 目录结构

- `lab1/`：实验一，浮点矩阵乘法基础、x87 汇编实现与 AVX2/FMA SIMD 向量化。
- `lab2/`：实验二，存储层次结构与 Cache 优化，包含循环重排与软件预取（prefetcht0）。
- `lab3/`：实验三，指令级并行度（ILP）挖掘（循环展开）与 OpenMP 多线程并行优化。
- `docs/`：课程实验指导书（Markdown / PDF）与实验报告模板。

---

## 核心优化方法

| 模块 | 核心技术 | 关键实现文件 |
| :--- | :--- | :--- |
| `lab1` | 64位整数打印修复 | `lab1/src/lab1/print_integer.S` |
| `lab1` | x87 浮点栈标量计算内核 | `lab1/src/lab1/gemm_kernel.S` |
| `lab1` | AVX2/FMA 向量化与 64B 内存对齐 | `lab1/src/lab1/gemm_kernel_avx2.cpp` |
| `lab2` | 矩阵乘循环重排与指针步进 | `lab2/src/lab2/gemm_kernel_opt_loop.S` |
| `lab2` | 软件数据预取（prefetcht0） | `lab2/src/lab2/gemm_kernel_opt_prefetch.S` |
| `lab3` | x87 2x 循环展开（ILP 挖掘） | `lab3/src/lab3/gemm_kernel_opt_loop_unrolling.S` |
| `lab3` | AVX2+FMA 汇编向量化内核宏 | `lab3/src/lab3/gemm_kernel_opt_avx.S` |
| `lab3` | OpenMP 多线程分块并行加速 | `lab3/src/lab3/openmp_gemm_opt.cpp` |

---

## 编译与测试

### 环境依赖
- Linux x86-64 环境（需支持 AVX2、FMA 指令集扩展）
- GCC / G++ (>= 9.0)
- CMake (>= 3.10)
- OpenMP 运行时

### 构建与验证
每个实验模块均为独立的 CMake 工程，进入对应模块目录后执行：

```bash
# 以 lab1 为例（lab2、lab3 同理）
cd lab1
mkdir -p build && cd build
cmake ..
cmake --build .

# 运行单元测试
ctest --output-on-failure
# 或直接执行测试二进制
./dist/bins/lab1_test_gemm_kernel.unittest
```

---

## 文档索引

完整实验指导书及相关资料见 [`docs/README.md`](docs/README.md)。
