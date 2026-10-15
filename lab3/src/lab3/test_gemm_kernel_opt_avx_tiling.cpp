#include <cmath>
#include <cstdint>
#include <vector>
#include "gtest/gtest.h"
#include "gemm_kernel_opt.h"

// Lab3 AVX microkernel requires M % 2 == 0 and N % 32 == 0.
// Verify multi-tile cases and the 2x32 partial 64x64 cache tile.
TEST(gemm_kernel_opt_avx, cache_tiles_across_64_boundaries) {
    struct Shape { int m, k, n; };
    const Shape shapes[] = {
        {2, 1, 32}, {64, 64, 128}, {130, 23, 96},
        {66, 127, 160}, {128, 256, 256}
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
        gemm_kernel_opt_avx(C.data(), A.data(), B.data(), s.m, s.n, s.k);
        for (size_t i = 0; i < C.size(); ++i)
            ASSERT_NEAR(C[i], expected[i], 1e-4f) << "index=" << i;
    }
}
