// Benchmark x87 FPU unroll factors 0, 2, 4 and 8 on identical matrices.
#include <chrono>
#include <cstdint>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <random>
#include <sstream>
#include <vector>
#include <algorithm>
#include "gemm_kernel_opt.h"

extern "C" {
void gemm_kernel_opt_unroll4(float *, float *, float *, uint64_t, uint64_t, uint64_t);
void gemm_kernel_opt_unroll8(float *, float *, float *, uint64_t, uint64_t, uint64_t);
}
using Gemm = void (*)(float *, float *, float *, uint64_t, uint64_t, uint64_t);

bool dimension(const char *text, uint64_t &value) {
    std::istringstream stream(text);
    return (stream >> value) && stream.eof() && value > 0;
}

int main(int argc, char **argv) {
    if (argc != 4) {
        std::cerr << "Usage: " << argv[0] << " <M> <K> <N>\n";
        return 1;
    }
    uint64_t M = 0, K = 0, N = 0;
    if (!dimension(argv[1], M) || !dimension(argv[2], K) || !dimension(argv[3], N) ||
        M > 4096 || K > 4096 || N > 4096) {
        std::cerr << "Specify three positive dimensions (each <= 4096).\n";
        return 1;
    }

    const int warmups = 10;
    const int iterations = 200;
    std::mt19937 rng(2026);
    std::uniform_real_distribution<float> random(-1.0f, 1.0f);
    std::vector<float> A(M * K), B(K * N), C(M * N, 0.0f);
    for (float &value : A) value = random(rng);
    for (float &value : B) value = random(rng);

    const struct { int factor; Gemm fn; } kernels[] = {
        {0, gemm_kernel_baseline},
        {2, gemm_kernel_opt_loop_unrolling},
        {4, gemm_kernel_opt_unroll4},
        {8, gemm_kernel_opt_unroll8},
    };
    std::ofstream csv("unroll_sweep.csv");
    if (!csv) {
        std::cerr << "Cannot write unroll_sweep.csv\n";
        return 1;
    }
    csv << "factor,gflops\n";
    std::cout << "Matrix (M,K,N): " << M << "," << K << "," << N << "\n";
    std::cout << "x87 FPU loop unrolling (same input matrices, 200 timed iterations)\n";
    std::cout << "Factor        GFLOPS\n";
    const double operations = 2.0 * double(M) * double(K) * double(N);
    for (const auto &kernel : kernels) {
        std::fill(C.begin(), C.end(), 0.0f);
        for (int i = 0; i < warmups; ++i) kernel.fn(C.data(), A.data(), B.data(), M, N, K);
        const auto start = std::chrono::steady_clock::now();
        for (int i = 0; i < iterations; ++i) kernel.fn(C.data(), A.data(), B.data(), M, N, K);
        const auto end = std::chrono::steady_clock::now();
        const double seconds = std::chrono::duration<double>(end - start).count();
        const double gflops = operations * iterations / seconds / 1.0e9;
        std::cout << std::setw(6) << kernel.factor << "    " << std::fixed
                  << std::setprecision(5) << std::setw(12) << gflops << "\n";
        csv << kernel.factor << "," << std::setprecision(10) << gflops << "\n";
    }
    std::cout << "Saved unroll_sweep.csv\n";
    return 0;
}
