#include <omp.h>
#include "openmp_gemm.h"
#include "gemm_kernel_opt.h"
#include <cstring>

#include <algorithm>

#include <algorithm>
#include <cstdlib>

struct AlignedBuffer {
    float* ptr = nullptr;
    size_t capacity = 0;

    float* get(size_t count) {
        if (count > capacity) {
            if (ptr) free(ptr);
            capacity = count + 1024;
            ptr = (float*)aligned_alloc(64, capacity * sizeof(float));
        }
        return ptr;
    }

    ~AlignedBuffer() {
        if (ptr) free(ptr);
    }
};

static thread_local AlignedBuffer tls_B;
static thread_local AlignedBuffer tls_C;
static thread_local AlignedBuffer tls_A;

inline int get_opt_thread_distribution(uint64_t M, uint64_t K, uint64_t N, int max_threads, int& m_thread, int& n_thread) {
    m_thread = 2;
    if (m_thread > max_threads) {
        m_thread = max_threads;
    }
    n_thread = max_threads / m_thread;
    if (n_thread < 1) n_thread = 1;
    return m_thread * n_thread;
}

void openmp_gemm_opt(int thread_num, float *C, float *A, float *B, uint64_t M, uint64_t N, uint64_t K){
    if (thread_num <= 0) thread_num = 1;
    if (M == 0 || N == 0 || K == 0) return;

    const int KERNEL_MR = 2, KERNEL_NR = 32;
    int m_thread = 1, n_thread = 1;
    int real_thread_num = get_opt_thread_distribution(M, K, N, thread_num, m_thread, n_thread);

#pragma omp parallel num_threads(real_thread_num) \
            default(none) \
            shared(C, A, B, M, N, K) \
            firstprivate(KERNEL_MR, KERNEL_NR, m_thread, n_thread)
    {
        int thread_id = omp_get_thread_num();
        int thread_id_m = thread_id / n_thread;
        int thread_id_n = thread_id % n_thread;

        int dim_m_per_thread = (M + m_thread - 1) / m_thread;
        int m_padding = dim_m_per_thread % KERNEL_MR;
        if (m_padding != 0) {
            m_padding = KERNEL_MR - m_padding;
        }
        int padded_m = dim_m_per_thread + m_padding;

        int dim_n_per_thread = (N + n_thread - 1) / n_thread;
        int n_padding = dim_n_per_thread % KERNEL_NR;
        if (n_padding != 0) {
            n_padding = KERNEL_NR - n_padding;
        }
        int padded_n = dim_n_per_thread + n_padding;

        int thread_m_start = thread_id_m * dim_m_per_thread;
        int thread_m_end = std::min((uint64_t)(thread_m_start + dim_m_per_thread), M);

        int thread_n_start = thread_id_n * dim_n_per_thread;
        int thread_n_end = std::min((uint64_t)(thread_n_start + dim_n_per_thread), N);

        int actual_m = thread_m_end - thread_m_start;
        int actual_n = thread_n_end - thread_n_start;

        if (actual_m > 0 && actual_n > 0) {
            float* A_ptr = nullptr;
            if (m_padding == 0 && actual_m == padded_m) {
                // Direct pointer to A, zero-copy!
                A_ptr = A + thread_m_start * K;
            } else {
                float* A_padding = tls_A.get(padded_m * K);
                memset(A_padding, 0, padded_m * K * sizeof(float));
                for (int m = thread_m_start; m < thread_m_end; m++) {
                    memcpy(A_padding + (m - thread_m_start) * K, A + m * K, K * sizeof(float));
                }
                A_ptr = A_padding;
            }

            float* B_padding = tls_B.get(padded_n * K);
            memset(B_padding, 0, padded_n * K * sizeof(float));

            float* C_padding = tls_C.get(padded_m * padded_n);
            memset(C_padding, 0, padded_m * padded_n * sizeof(float));

            // Pack B
            for (uint64_t k = 0; k < K; k++) {
                memcpy(B_padding + k * padded_n,
                       B + thread_n_start + k * N,
                       actual_n * sizeof(float));
            }

            // Pack C
            for (int m = thread_m_start; m < thread_m_end; m++) {
                memcpy(C_padding + (m - thread_m_start) * padded_n,
                       C + m * N + thread_n_start,
                       actual_n * sizeof(float));
            }

            gemm_kernel_opt_avx(C_padding, A_ptr, B_padding, padded_m, padded_n, K);

            // Unpack C
            for (int m = thread_m_start; m < thread_m_end; m++) {
                memcpy(C + m * N + thread_n_start,
                       C_padding + (m - thread_m_start) * padded_n,
                       actual_n * sizeof(float));
            }
        }
    }
}
