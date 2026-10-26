# 实验三练习一：循环展开度性能对比

对比 x87 FPU 的 N 维度循环展开度 **0（Baseline）、2、4、8**。4/8 倍版本使用汇编期循环展开的 2 元素计算块，并提供对非整倍数 N 的标量尾部处理。

在 Ubuntu 实验机的仓库根目录编译（如果此前已配置本地 GoogleTest，则继续复用）：

```bash
cmake -S labs/lab3 -B labs/lab3/build -DCMAKE_BUILD_TYPE=Release -DFETCHCONTENT_SOURCE_DIR_GOOGLETEST=/usr/src/googletest
cmake --build labs/lab3/build --target lab3_gemm_unroll_sweep lab3_gemm_unroll_extra.unittest
cd labs/lab3/build
./dist/bins/lab3_gemm_unroll_extra.unittest
./dist/bins/lab3_gemm_unroll_sweep 256 256 256
python3 ../tools/plot_unroll.py
```

测试结果 `unroll_sweep.csv` 和性能曲线 `unroll_sweep.svg` 会生成在 `labs/lab3/build`。打开 SVG 即可截图插入实验报告。记录实验机实测数据，并分析循环展开度改变后性能并不一定单调增长的原因。

`lab3_gemm_opt_loop_unrolling`（原练习的 0/2 对比）保持原有用法和实现，不受本扩展影响。
