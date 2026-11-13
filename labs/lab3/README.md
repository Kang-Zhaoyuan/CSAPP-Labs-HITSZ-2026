# 循环展开、AVX 与 OpenMP

AVX 微内核为 2×32，外层使用 64×64 缓存分块；OpenMP 路径通过 Packing/Padding 支持非对齐尺寸。

在仓库根目录构建后，比较 x87 的 0、2、4、8 倍 N 维循环展开：

```bash
cmake -S labs/lab3 -B labs/lab3/build -DCMAKE_BUILD_TYPE=Release
cmake --build labs/lab3/build --parallel
ctest --test-dir labs/lab3/build --output-on-failure --no-tests=error
cd labs/lab3/build
./dist/bins/lab3_gemm_unroll_sweep 256 256 256
python3 ../tools/plot_unroll.py
```

CSV 与 SVG 生成在 `build/`。展开度受寄存器压力、指令调度与代码体积影响，性能未必单调增长。

[完整指导书](../../docs/实验3/)
