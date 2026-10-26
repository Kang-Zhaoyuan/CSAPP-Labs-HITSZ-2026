#include <algorithm>
#include <cmath>
#include <cstdint>
#include <random>
#include <vector>
#include "gtest/gtest.h"

extern "C" {
void gemm_kernel_opt_unroll4(float *, float *, float *, uint64_t, uint64_t, uint64_t);
void gemm_kernel_opt_unroll8(float *, float *, float *, uint64_t, uint64_t, uint64_t);
}
using Kernel = void (*)(float *, float *, float *, uint64_t, uint64_t, uint64_t);

static void verify(Kernel kernel, uint64_t M, uint64_t K, uint64_t N) {
    std::mt19937 generator(2026);
    std::uniform_real_distribution<float> random(-0.5f, 0.5f);
    std::vector<float> A(M * K), B(K * N), C(M * N, 0.0f), expected(M * N, 0.0f);
    for (float &x : A) x = random(generator);
    for (float &x : B) x = random(generator);
    for (uint64_t m = 0; m < M; ++m)
        for (uint64_t k = 0; k < K; ++k)
            for (uint64_t n = 0; n < N; ++n)
                expected[m * N + n] += A[m * K + k] * B[k * N + n];
    kernel(C.data(), A.data(), B.data(), M, N, K);
    for (uint64_t i = 0; i < M * N; ++i)
        ASSERT_NEAR(C[i], expected[i], 1e-4f) << "M=" << M << ",K=" << K
            << ",N=" << N << ",i=" << i;
}

TEST(gemm_unroll_extra, factor4_varied_shapes) {
    const uint64_t shapes[][3] = {{1,1,1},{2,3,3},{5,7,5},{8,13,7},
                                   {17,8,9},{16,32,16},{8,64,33}};
    for (const auto &shape : shapes) verify(gemm_kernel_opt_unroll4, shape[0], shape[1], shape[2]);
}

TEST(gemm_unroll_extra, factor8_varied_shapes) {
    const uint64_t shapes[][3] = {{1,1,1},{2,3,3},{5,7,5},{8,13,7},
                                   {17,8,9},{16,32,16},{8,64,33}};
    for (const auto &shape : shapes) verify(gemm_kernel_opt_unroll8, shape[0], shape[1], shape[2]);
}
