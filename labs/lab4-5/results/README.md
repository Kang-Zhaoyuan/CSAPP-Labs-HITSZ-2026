# GPU 实测数据

- [lab4_performance.csv](lab4_performance.csv)：全局内存基线，块宽 8/16/32，各 12 个矩阵尺寸。
- [lab5_results.csv](lab5_results.csv)：共享内存与 cuBLAS；`dataset` 区分正确性扫描和性能扫描，每个配置各记录一次。

`time_ms` 为内核耗时，`GFLOPS` 为吞吐，`errors` 为误差检查计数。原始归档未记录 GPU 型号与 CUDA 版本，不能据此推断其他硬件上的性能。

数据于 2026-10-30 归档；对应实现提交 `0c4655b3`。重新评测见 [benchmark.sh](../benchmark.sh)。
