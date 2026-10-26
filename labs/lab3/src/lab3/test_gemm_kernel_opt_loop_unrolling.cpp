#include <iostream>
#include <random>
#include <vector>

#include "gtest/gtest.h"
#include "gemm_kernel_opt.h"

using namespace std;

TEST(gemm_kernel_opt_loop_unrolling, test0) {
    // 测试正确性
    const int M = 64, N =64, K = 64;

    std::random_device rd;  //Will be used to obtain a seed for the random number engine
    std::mt19937 gen(rd()); //Standard mersenne_twister_engine seeded with rd()
    std::uniform_real_distribution<float> dis(0.0, 1.0);

    auto* A = new float [M * K];
    auto* B = new float [K * N];
    auto* C = new float [M * N];
    auto* C_check = new float [M * N];
    // 初始化A
    for(int m = 0; m < M; m ++) {
        for(int k = 0; k < K; k ++) {
            A[m * K + k] = dis(gen);
        }
    }

    // 初始化B
    for(int k = 0; k < K; k ++) {
        for(int n = 0; n < N; n ++) {
            B[k * N + n] = dis(gen);
        }
    }

    memset((void *)C_check, 0, M * N * sizeof(float));

    // 计算校验结果
    double result = 0;
    for (int m = 0; m < M; m++) {
        for (int n = 0; n < N; n ++) {
            result = 0;
            for(int k = 0; k < K; k ++) {
                result += double(A[m * K + k] * B[k * N + n]);
            }
            C_check[m * N + n] = (float)result;
        }
    }

    // 初始化C
    memset((void *)C, 0, M * N * sizeof(float));

    // 调用矩阵乘法
    gemm_kernel_opt_loop_unrolling(
            C, A, B, M, N, K
    );

    // 校验结果矩阵
    for (int m = 0; m < M; m ++) {
        for (int n = 0; n < N; n ++) {
            ASSERT_NEAR(C[m * N + n], C_check[m * N + n], 1e-5) << "C["<<m * N + n<<"](m="<< m <<", M="<<M<<", n="<<n<<", N="<<N<<", K="<<K<<") is abnormal!"<<endl;
        }
    }

    delete[] A;
    delete[] B;
    delete[] C;
    delete[] C_check;
}

TEST(gemm_kernel_opt_loop_unrolling, odd_n_tail) {
    const int M = 3, N = 5, K = 7;
    std::vector<float> A(M * K), B(K * N), C(M * N, 0.0f), expected(M * N, 0.0f);

    for (int i = 0; i < M * K; ++i) A[i] = static_cast<float>(i % 11) / 10.0f;
    for (int i = 0; i < K * N; ++i) B[i] = static_cast<float>((i * 3) % 13) / 13.0f;

    for (int m = 0; m < M; ++m) {
        for (int n = 0; n < N; ++n) {
            for (int k = 0; k < K; ++k) {
                expected[m * N + n] += A[m * K + k] * B[k * N + n];
            }
        }
    }

    gemm_kernel_opt_loop_unrolling(C.data(), A.data(), B.data(), M, N, K);

    for (int i = 0; i < M * N; ++i) {
        ASSERT_NEAR(C[i], expected[i], 1e-5);
    }
}

TEST(gemm_kernel_opt_loop_unrolling, test1) {
    // 测试正确性
    const int M = 16, N =128, K = 64;

    std::random_device rd;  //Will be used to obtain a seed for the random number engine
    std::mt19937 gen(rd()); //Standard mersenne_twister_engine seeded with rd()
    std::uniform_real_distribution<float> dis(0.0, 1.0);

    auto* A = new float [M * K];
    auto* B = new float [K * N];
    auto* C = new float [M * N];
    auto* C_check = new float [M * N];
    // 初始化A
    for(int m = 0; m < M; m ++) {
        for(int k = 0; k < K; k ++) {
            A[m * K + k] = dis(gen);
        }
    }

    // 初始化B
    for(int k = 0; k < K; k ++) {
        for(int n = 0; n < N; n ++) {
            B[k * N + n] = dis(gen);
        }
    }

    memset((void *)C_check, 0, M * N * sizeof(float));

    // 计算校验结果
    double result = 0;
    for (int m = 0; m < M; m++) {
        for (int n = 0; n < N; n ++) {
            result = 0;
            for(int k = 0; k < K; k ++) {
                result += double(A[m * K + k] * B[k * N + n]);
            }
            C_check[m * N + n] = (float)result;
        }
    }

    // 初始化C
    memset((void *)C, 0, M * N * sizeof(float));

    // 调用矩阵乘法
    gemm_kernel_opt_loop_unrolling(
            C, A, B, M, N, K
    );

    // 校验结果矩阵
    for (int m = 0; m < M; m ++) {
        for (int n = 0; n < N; n ++) {
            ASSERT_NEAR(C[m * N + n], C_check[m * N + n], 1e-5) << "C["<<m * N + n<<"](m="<< m <<", M="<<M<<", n="<<n<<", N="<<N<<", K="<<K<<") is abnormal!"<<endl;
        }
    }

    delete[] A;
    delete[] B;
    delete[] C;
    delete[] C_check;
}

TEST(gemm_kernel_opt_loop_unrolling, test2) {
    // 测试正确性
    const int M = 256, N =64, K = 16;

    std::random_device rd;  //Will be used to obtain a seed for the random number engine
    std::mt19937 gen(rd()); //Standard mersenne_twister_engine seeded with rd()
    std::uniform_real_distribution<float> dis(0.0, 1.0);

    auto* A = new float [M * K];
    auto* B = new float [K * N];
    auto* C = new float [M * N];
    auto* C_check = new float [M * N];
    // 初始化A
    for(int m = 0; m < M; m ++) {
        for(int k = 0; k < K; k ++) {
            A[m * K + k] = dis(gen);
        }
    }

    // 初始化B
    for(int k = 0; k < K; k ++) {
        for(int n = 0; n < N; n ++) {
            B[k * N + n] = dis(gen);
        }
    }

    memset((void *)C_check, 0, M * N * sizeof(float));

    // 计算校验结果
    double result = 0;
    for (int m = 0; m < M; m++) {
        for (int n = 0; n < N; n ++) {
            result = 0;
            for(int k = 0; k < K; k ++) {
                result += double(A[m * K + k] * B[k * N + n]);
            }
            C_check[m * N + n] = (float)result;
        }
    }

    // 初始化C
    memset((void *)C, 0, M * N * sizeof(float));

    // 调用矩阵乘法
    gemm_kernel_opt_loop_unrolling(
            C, A, B, M, N, K
    );

    // 校验结果矩阵
    for (int m = 0; m < M; m ++) {
        for (int n = 0; n < N; n ++) {
            ASSERT_NEAR(C[m * N + n], C_check[m * N + n], 1e-5) << "C["<<m * N + n<<"](m="<< m <<", M="<<M<<", n="<<n<<", N="<<N<<", K="<<K<<") is abnormal!"<<endl;
        }
    }

    delete[] A;
    delete[] B;
    delete[] C;
    delete[] C_check;
}
