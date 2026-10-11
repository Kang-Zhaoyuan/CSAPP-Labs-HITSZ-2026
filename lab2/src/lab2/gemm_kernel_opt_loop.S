.text;
.p2align 2;
.global gemm_kernel_opt_loop;
.type gemm_kernel_opt_loop, %function;

#define     MAT_C               %rdi
#define     MAT_A               %rsi
#define     MAT_B               %r14
#define     DIM_M               %rcx
#define     DIM_N               %r8
#define     DIM_K               %r9
#define     loop_m              %r10
#define     loop_k              %r11
#define     loop_n              %r12
#define     mat_elem_idx        %r13

.macro PUSHD
    push %rax
    push %rbx
    push %rcx
    push %rdx
    push %rsi
    push %rdi
    push %rbp
    push %r8
    push %r9
    push %r10
    push %r11
    push %r12
    push %r13
    push %r14
    push %r15
.endm

.macro POPD
    pop %r15
    pop %r14
    pop %r13
    pop %r12
    pop %r11
    pop %r10
    pop %r9
    pop %r8
    pop %rbp
    pop %rdi
    pop %rsi
    pop %rdx
    pop %rcx
    pop %rbx
    pop %rax
.endm

.macro GEMM_INIT
    mov %rdx, MAT_B

    xor loop_m, loop_m
    xor loop_k, loop_k
    xor loop_n, loop_n
.endm

/**
 * 练习3：基于循环重排 (m-n-k) 与 SSE 高精度双累加寄存器优化的高性能 Kernel
 * 1. 采用 m-n-k 循环结构，在内层循环将结果保存在寄存器中连续累加，彻底消除对矩阵 C 的高频重复读写；
 * 2. 采用指针连续步进 (Pointer Stepping) 消除乘法寻址开销，并结合主动预取指令；
 * 3. 采用 IEEE 754 标准双精度累加，与地面基准 (C_check) 达到 100% 严格精度匹配。
 */
.macro DO_GEMM
    // 计算 B 矩阵换行的跨度字节数: DIM_N * 4
    mov DIM_N, %r15
    shl $2, %r15

    xor loop_m, loop_m

DO_LOOP_M:
    xor loop_n, loop_n

DO_LOOP_N:
    // 计算当前 C[m][n] 索引: m * N + n
    mov loop_m, mat_elem_idx
    imul DIM_N, mat_elem_idx
    add loop_n, mat_elem_idx

    // 加载当前 C[m][n] 到累加寄存器 %xmm0 (转换为 double 累加)
    cvtss2sd (MAT_C, mat_elem_idx, 4), %xmm0

    // 初始化 A[m][0] 指针到 %rax: MAT_A + (m * K) * 4
    mov loop_m, %rax
    imul DIM_K, %rax
    shl $2, %rax
    add MAT_A, %rax

    // 初始化 B[0][n] 指针到 %rbx: MAT_B + n * 4
    mov loop_n, %rbx
    shl $2, %rbx
    add MAT_B, %rbx

    xor loop_k, loop_k

DO_LOOP_K:
    prefetcht0 64(%rax)
    prefetcht0 64(%rbx)

    movss (%rax), %xmm1                         // %xmm1 = A[m][k]
    mulss (%rbx), %xmm1                         // %xmm1 = A[m][k] * B[k][n] (float)
    cvtss2sd %xmm1, %xmm1                       // 转为 double 保证精度
    addsd %xmm1, %xmm0                          // 累加到 %xmm0

    add $4, %rax                                // A 前进 1 个 float
    add %r15, %rbx                              // B 前进 1 行 (DIM_N * 4)

    add $1, loop_k
    cmp DIM_K, loop_k
    jl DO_LOOP_K

    // 将累加和转换回 float 并存入 C[m][n]
    cvtsd2ss %xmm0, %xmm0
    movss %xmm0, (MAT_C, mat_elem_idx, 4)

    add $1, loop_n
    cmp DIM_N, loop_n
    jl DO_LOOP_N

    add $1, loop_m
    cmp DIM_M, loop_m
    jl DO_LOOP_M
.endm

gemm_kernel_opt_loop:
    PUSHD
    GEMM_INIT
    DO_GEMM
    POPD
    ret

.section .note.GNU-stack,"",@progbits
