cmake_minimum_required(VERSION 3.10)

project(computer_architecture_lab3
        VERSION 1.0.0)


enable_language(ASM)

find_package(OpenMP REQUIRED)

add_executable(
        lab3_gemm_opt_loop_unrolling
        gemm_kernel_opt_loop_unrolling.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/gemm_kernel_opt_loop_unrolling.S
        ${CMAKE_CURRENT_SOURCE_DIR}/gemm_kernel_baseline.S
)


target_include_directories(lab3_gemm_opt_loop_unrolling
        PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}
)

# 应用avx
add_executable(
        lab3_gemm_opt_avx
        gemm_kernel_opt_avx.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/gemm_kernel_opt_avx.S
        ${CMAKE_CURRENT_SOURCE_DIR}/gemm_kernel_baseline.S
)


target_include_directories(lab3_gemm_opt_avx
        PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}
)

# 应用openmp
add_executable(
        lab3_gemm_opt_openmp
        gemm_kernel_opt_openmp.cpp
        openmp_gemm_baseline.cpp
        openmp_gemm_opt.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/gemm_kernel_opt_avx.S
        ${CMAKE_CURRENT_SOURCE_DIR}/gemm_kernel_baseline.S
)


target_include_directories(lab3_gemm_opt_openmp
        PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}
)

target_link_libraries(lab3_gemm_opt_openmp
        PUBLIC OpenMP::OpenMP_CXX)


enable_testing()

include(FetchContent)
FetchContent_Declare(
        googletest
        GIT_REPOSITORY https://github.com/google/googletest.git
        GIT_TAG v1.14.0
)

#使gtest可用
FetchContent_MakeAvailable(googletest)

add_executable(
        lab3_gemm_opt_loop_unrolling.unittest
        test_gemm_kernel_opt_loop_unrolling.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/gemm_kernel_opt_loop_unrolling.S
        ${CMAKE_CURRENT_SOURCE_DIR}/gemm_kernel_baseline.S
)


target_link_libraries(
        lab3_gemm_opt_loop_unrolling.unittest
        PRIVATE gtest
        PRIVATE gtest_main
)


target_include_directories(
        lab3_gemm_opt_loop_unrolling.unittest
        PRIVATE ${gtest_SOURCE_DIR}/include
)

# avx相关的测试
add_executable(
        lab3_gemm_opt_avx.unittest
        test_gemm_kernel_opt_avx.cpp
        test_gemm_kernel_opt_avx_tiling.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/gemm_kernel_opt_avx.S
)


target_link_libraries(
        lab3_gemm_opt_avx.unittest
        PRIVATE gtest
        PRIVATE gtest_main
)


target_include_directories(
        lab3_gemm_opt_avx.unittest
        PRIVATE ${gtest_SOURCE_DIR}/include
)

# openmp相关的测试
add_executable(
        lab3_gemm_opt_openmp.unittest
        test_openmp_gemm.cpp
        openmp_gemm_opt.cpp
        ${CMAKE_CURRENT_SOURCE_DIR}/gemm_kernel_opt_avx.S
)


target_link_libraries(
        lab3_gemm_opt_openmp.unittest
        PRIVATE gtest
        PRIVATE gtest_main
)


target_include_directories(
        lab3_gemm_opt_openmp.unittest
        PRIVATE ${gtest_SOURCE_DIR}/include
)

target_link_libraries(lab3_gemm_opt_openmp.unittest
        PUBLIC OpenMP::OpenMP_CXX)



# Exercise 1, step 8: compare N-loop unroll factors 0, 2, 4 and 8.
add_executable(
        lab3_gemm_unroll_sweep
        gemm_unroll_sweep.cpp
        gemm_kernel_baseline.S
        gemm_kernel_opt_loop_unrolling.S
        gemm_kernel_opt_unroll_extra.S
)
target_include_directories(lab3_gemm_unroll_sweep
        PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}
)

add_executable(
        lab3_gemm_unroll_extra.unittest
        test_gemm_unroll_extra.cpp
        gemm_kernel_opt_unroll_extra.S
)
target_link_libraries(lab3_gemm_unroll_extra.unittest
        PRIVATE gtest
        PRIVATE gtest_main
)
target_include_directories(lab3_gemm_unroll_extra.unittest
        PRIVATE ${gtest_SOURCE_DIR}/include
)

include(GoogleTest)
gtest_discover_tests(lab3_gemm_opt_loop_unrolling.unittest)
gtest_discover_tests(lab3_gemm_opt_avx.unittest)
gtest_discover_tests(lab3_gemm_opt_openmp.unittest)
gtest_discover_tests(lab3_gemm_unroll_extra.unittest)
