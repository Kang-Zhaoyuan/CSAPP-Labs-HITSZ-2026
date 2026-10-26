#include <iostream>
#include <random>
#include <vector>

#include "gtest/gtest.h"
#include "openmp_gemm.h"

using namespace std;

TEST(openmp_gemm_opt, test0) {
    // 测试正确性
    const int M = 4, N = 64, K = 32;
    const int thread_num = 2;

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
    openmp_gemm_opt(
            thread_num, C, A, B, M, N, K
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

TEST(openmp_gemm_opt, arbitrary_shape_padding) {
    const int M = 3, N = 35, K = 5;
    const int thread_num = 7;
    std::vector<float> A(M * K), B(K * N), C(M * N, 0.0f), expected(M * N, 0.0f);

    for (int i = 0; i < M * K; ++i) A[i] = static_cast<float>(i % 7) / 7.0f;
    for (int i = 0; i < K * N; ++i) B[i] = static_cast<float>((i * 5) % 17) / 17.0f;

    for (int m = 0; m < M; ++m) {
        for (int n = 0; n < N; ++n) {
            for (int k = 0; k < K; ++k) {
                expected[m * N + n] += A[m * K + k] * B[k * N + n];
            }
        }
    }

    openmp_gemm_opt(thread_num, C.data(), A.data(), B.data(), M, N, K);

    for (int i = 0; i < M * N; ++i) {
        ASSERT_NEAR(C[i], expected[i], 1e-5);
    }
}

TEST(openmp_gemm_opt, test1) {
    // 测试正确性
    const int M = 256, N = 256, K = 256;
    const int thread_num = 4;

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
    openmp_gemm_opt(
            thread_num, C, A, B, M, N, K
    );

    // 校验结果矩阵
    for (int m = 0; m < M; m ++) {
        for (int n = 0; n < N; n ++) {
            ASSERT_NEAR(C[m * N + n], C_check[m * N + n], 1e-4) << "C["<<m * N + n<<"](m="<< m <<", M="<<M<<", n="<<n<<", N="<<N<<", K="<<K<<") is abnormal!"<<endl;
        }
    }

    delete[] A;
    delete[] B;
    delete[] C;
    delete[] C_check;
}

TEST(openmp_gemm_opt, test2) {
    // 测试正确性
    const int M = 512, N = 512, K = 512;
    const int thread_num = 8;

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
    openmp_gemm_opt(
            thread_num, C, A, B, M, N, K
    );

    // 校验结果矩阵
    for (int m = 0; m < M; m ++) {
        for (int n = 0; n < N; n ++) {
            ASSERT_NEAR(C[m * N + n], C_check[m * N + n], 1e-3) << "C["<<m * N + n<<"](m="<< m <<", M="<<M<<", n="<<n<<", N="<<N<<", K="<<K<<") is abnormal!"<<endl;
        }
    }

    delete[] A;
    delete[] B;
    delete[] C;
    delete[] C_check;
}

TEST(openmp_gemm_opt, test3) {
    // 测试正确性
    const int M = 1024, N = 1024, K = 1024;
    const int thread_num = 16;

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
    openmp_gemm_opt(
            thread_num, C, A, B, M, N, K
    );

    // 校验结果矩阵
    for (int m = 0; m < M; m ++) {
        for (int n = 0; n < N; n ++) {
            ASSERT_NEAR(C[m * N + n], C_check[m * N + n], 1e-3) << "C["<<m * N + n<<"](m="<< m <<", M="<<M<<", n="<<n<<", N="<<N<<", K="<<K<<") is abnormal!"<<endl;
        }
    }

    delete[] A;
    delete[] B;
    delete[] C;
    delete[] C_check;
}
