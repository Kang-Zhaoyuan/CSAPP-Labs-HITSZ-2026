#include <cmath>
#include <cstdint>
#include <vector>
#include "gtest/gtest.h"
#include "gemm_kernel.h"

// Lab2 SSE kernel: verify 32x32 tile boundaries, nonzero C, and long K.
TEST(gemm_kernel_opt_loop, cache_tiles_and_partial_edges) {
    struct Shape { int m, k, n; };
    const Shape shapes[] = {
        {1, 1, 1}, {3, 7, 5}, {31, 33, 67},
        {33, 65, 35}, {64, 64, 64}, {4, 32768, 4}
    };

    for (const Shape s : shapes) {
        SCOPED_TRACE(::testing::Message()
                     << "M=" << s.m << " K=" << s.k << " N=" << s.n);
        std::vector<float> A(s.m * s.k), B(s.k * s.n);
        std::vector<float> C(s.m * s.n, 0.25f);
        for (size_t i = 0; i < A.size(); ++i)
            A[i] = static_cast<float>(i % 11) / 10.0f;
        for (size_t i = 0; i < B.size(); ++i)
            B[i] = static_cast<float>((i * 3) % 13) / 13.0f;

        // Match the reference: float products, double reduction, float result.
        std::vector<float> expected(C.size());
        for (int m = 0; m < s.m; ++m) {
            for (int n = 0; n < s.n; ++n) {
                double sum = 0.25;
                for (int k = 0; k < s.k; ++k) {
                    const float product = A[m * s.k + k] * B[k * s.n + n];
                    sum += static_cast<double>(product);
                }
                expected[m * s.n + n] = static_cast<float>(sum);
            }
        }
        gemm_kernel_opt_loop(C.data(), A.data(), B.data(), s.m, s.n, s.k);
        for (size_t i = 0; i < C.size(); ++i)
            ASSERT_NEAR(C[i], expected[i], 1e-5f) << "index=" << i;
    }
}
