#include <immintrin.h>
#include <cstdint>
#include "gemm_kernel.h"

extern "C" {

/**
 * AVX2 + FMA SIMD 向量化矩阵乘法核
 * 支持 64 字节内存对齐的高速向量运算
 * C[M x N] = A[M x K] * B[K x N]
 */
void gemm_kernel_avx2_aligned(float *C, const float *A, const float *B, uint64_t M, uint64_t N, uint64_t K) {
    uint64_t m = 0;

    // 4x32 微内核展开：每次计算 4 行 C，每行 32 个 float (4 个 __m256 向量)
    for (; m + 3 < M; m += 4) {
        float *c0 = C + (m + 0) * N;
        float *c1 = C + (m + 1) * N;
        float *c2 = C + (m + 2) * N;
        float *c3 = C + (m + 3) * N;

        const float *a0 = A + (m + 0) * K;
        const float *a1 = A + (m + 1) * K;
        const float *a2 = A + (m + 2) * K;
        const float *a3 = A + (m + 3) * K;

        uint64_t n = 0;
        for (; n + 31 < N; n += 32) {
            __m256 c0_0 = _mm256_loadu_ps(c0 + n + 0);
            __m256 c0_1 = _mm256_loadu_ps(c0 + n + 8);
            __m256 c0_2 = _mm256_loadu_ps(c0 + n + 16);
            __m256 c0_3 = _mm256_loadu_ps(c0 + n + 24);

            __m256 c1_0 = _mm256_loadu_ps(c1 + n + 0);
            __m256 c1_1 = _mm256_loadu_ps(c1 + n + 8);
            __m256 c1_2 = _mm256_loadu_ps(c1 + n + 16);
            __m256 c1_3 = _mm256_loadu_ps(c1 + n + 24);

            __m256 c2_0 = _mm256_loadu_ps(c2 + n + 0);
            __m256 c2_1 = _mm256_loadu_ps(c2 + n + 8);
            __m256 c2_2 = _mm256_loadu_ps(c2 + n + 16);
            __m256 c2_3 = _mm256_loadu_ps(c2 + n + 24);

            __m256 c3_0 = _mm256_loadu_ps(c3 + n + 0);
            __m256 c3_1 = _mm256_loadu_ps(c3 + n + 8);
            __m256 c3_2 = _mm256_loadu_ps(c3 + n + 16);
            __m256 c3_3 = _mm256_loadu_ps(c3 + n + 24);

            for (uint64_t k = 0; k < K; ++k) {
                const float *b_k = B + k * N + n;
                __m256 b_0 = _mm256_loadu_ps(b_k + 0);
                __m256 b_1 = _mm256_loadu_ps(b_k + 8);
                __m256 b_2 = _mm256_loadu_ps(b_k + 16);
                __m256 b_3 = _mm256_loadu_ps(b_k + 24);

                __m256 a0_v = _mm256_set1_ps(a0[k]);
                c0_0 = _mm256_fmadd_ps(a0_v, b_0, c0_0);
                c0_1 = _mm256_fmadd_ps(a0_v, b_1, c0_1);
                c0_2 = _mm256_fmadd_ps(a0_v, b_2, c0_2);
                c0_3 = _mm256_fmadd_ps(a0_v, b_3, c0_3);

                __m256 a1_v = _mm256_set1_ps(a1[k]);
                c1_0 = _mm256_fmadd_ps(a1_v, b_0, c1_0);
                c1_1 = _mm256_fmadd_ps(a1_v, b_1, c1_1);
                c1_2 = _mm256_fmadd_ps(a1_v, b_2, c1_2);
                c1_3 = _mm256_fmadd_ps(a1_v, b_3, c1_3);

                __m256 a2_v = _mm256_set1_ps(a2[k]);
                c2_0 = _mm256_fmadd_ps(a2_v, b_0, c2_0);
                c2_1 = _mm256_fmadd_ps(a2_v, b_1, c2_1);
                c2_2 = _mm256_fmadd_ps(a2_v, b_2, c2_2);
                c2_3 = _mm256_fmadd_ps(a2_v, b_3, c2_3);

                __m256 a3_v = _mm256_set1_ps(a3[k]);
                c3_0 = _mm256_fmadd_ps(a3_v, b_0, c3_0);
                c3_1 = _mm256_fmadd_ps(a3_v, b_1, c3_1);
                c3_2 = _mm256_fmadd_ps(a3_v, b_2, c3_2);
                c3_3 = _mm256_fmadd_ps(a3_v, b_3, c3_3);
            }

            _mm256_storeu_ps(c0 + n + 0, c0_0);
            _mm256_storeu_ps(c0 + n + 8, c0_1);
            _mm256_storeu_ps(c0 + n + 16, c0_2);
            _mm256_storeu_ps(c0 + n + 24, c0_3);

            _mm256_storeu_ps(c1 + n + 0, c1_0);
            _mm256_storeu_ps(c1 + n + 8, c1_1);
            _mm256_storeu_ps(c1 + n + 16, c1_2);
            _mm256_storeu_ps(c1 + n + 24, c1_3);

            _mm256_storeu_ps(c2 + n + 0, c2_0);
            _mm256_storeu_ps(c2 + n + 8, c2_1);
            _mm256_storeu_ps(c2 + n + 16, c2_2);
            _mm256_storeu_ps(c2 + n + 24, c2_3);

            _mm256_storeu_ps(c3 + n + 0, c3_0);
            _mm256_storeu_ps(c3 + n + 8, c3_1);
            _mm256_storeu_ps(c3 + n + 16, c3_2);
            _mm256_storeu_ps(c3 + n + 24, c3_3);
        }

        // 处理 N 维度 8 元素余项
        for (; n + 7 < N; n += 8) {
            __m256 c0_v = _mm256_loadu_ps(c0 + n);
            __m256 c1_v = _mm256_loadu_ps(c1 + n);
            __m256 c2_v = _mm256_loadu_ps(c2 + n);
            __m256 c3_v = _mm256_loadu_ps(c3 + n);

            for (uint64_t k = 0; k < K; ++k) {
                __m256 b_v = _mm256_loadu_ps(B + k * N + n);
                c0_v = _mm256_fmadd_ps(_mm256_set1_ps(a0[k]), b_v, c0_v);
                c1_v = _mm256_fmadd_ps(_mm256_set1_ps(a1[k]), b_v, c1_v);
                c2_v = _mm256_fmadd_ps(_mm256_set1_ps(a2[k]), b_v, c2_v);
                c3_v = _mm256_fmadd_ps(_mm256_set1_ps(a3[k]), b_v, c3_v);
            }

            _mm256_storeu_ps(c0 + n, c0_v);
            _mm256_storeu_ps(c1 + n, c1_v);
            _mm256_storeu_ps(c2 + n, c2_v);
            _mm256_storeu_ps(c3 + n, c3_v);
        }

        // 处理 N 维度标量余项
        for (; n < N; ++n) {
            for (uint64_t k = 0; k < K; ++k) {
                float b_val = B[k * N + n];
                c0[n] += a0[k] * b_val;
                c1[n] += a1[k] * b_val;
                c2[n] += a2[k] * b_val;
                c3[n] += a3[k] * b_val;
            }
        }
    }

    // 处理 M 维度余项
    for (; m < M; ++m) {
        float *c_row = C + m * N;
        const float *a_row = A + m * K;

        uint64_t n = 0;
        for (; n + 7 < N; n += 8) {
            __m256 c_v = _mm256_loadu_ps(c_row + n);
            for (uint64_t k = 0; k < K; ++k) {
                __m256 a_v = _mm256_set1_ps(a_row[k]);
                __m256 b_v = _mm256_loadu_ps(B + k * N + n);
                c_v = _mm256_fmadd_ps(a_v, b_v, c_v);
            }
            _mm256_storeu_ps(c_row + n, c_v);
        }

        for (; n < N; ++n) {
            float sum = 0.0f;
            for (uint64_t k = 0; k < K; ++k) {
                sum += a_row[k] * B[k * N + n];
            }
            c_row[n] += sum;
        }
    }
}

}
