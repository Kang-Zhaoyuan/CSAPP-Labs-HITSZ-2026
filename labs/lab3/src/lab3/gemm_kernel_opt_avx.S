.text;
.p2align 2;
.global gemm_kernel_opt_avx;
.type gemm_kernel_opt_avx, %function;


#define     AVX_REG_BYTE_WIDTH  32

#define     MAT_C               %rdi
#define     MAT_A               %rsi
#define     MAT_B               %r13
#define     DIM_M               %rcx
#define     DIM_N               %r8
#define     DIM_K               %r9
#define     loop_m              %r10
#define     loop_k              %r11
#define     loop_n              %r12
#define     mat_elem_idx        %r14
#define     temp_reg            %r15

// 以下是计算过程中用到的avx寄存器
#define     mat_c0_0_8           %ymm0
#define     mat_c0_8_16          %ymm1
#define     mat_c0_16_24         %ymm2
#define     mat_c0_24_32         %ymm3
#define     mat_c1_0_8           %ymm4
#define     mat_c1_8_16          %ymm5
#define     mat_c1_16_24         %ymm6
#define     mat_c1_24_32         %ymm7
#define     mat_a0_0_8           %ymm8
#define     mat_a1_0_8           %ymm9
#define     mat_b0_0_8           %ymm10
#define     mat_b0_8_16          %ymm11
#define     mat_b0_16_24         %ymm12
#define     mat_b0_24_32         %ymm13

.macro PUSHD   // 保存原通用寄存器值
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

.macro POPD    // 恢复原通用寄存器值
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
.endm

.macro LOAD_MAT_A     // 每次装载矩阵A同一列的2个元素, 即A[m][k], A[m+1][k]
    // 装载A[m][k]的数据
    mov loop_m, %rax
    mul DIM_K
    mov %rax, temp_reg
    add loop_k, temp_reg

    // 计算A[m][k]的字节地址
    mov temp_reg, mat_elem_idx
    shl $2, mat_elem_idx        // 左移，相当于乘4

    vbroadcastss (MAT_A, mat_elem_idx), mat_a0_0_8    // 将A[m][k]广播到AVX寄存器的8个单元

    // TODO 练习3: 请添加加载并广播A[m+1][k]-->mat_a1_0_8的逻辑
    mov temp_reg, mat_elem_idx
    add DIM_K, mat_elem_idx
    shl $2, mat_elem_idx
    vbroadcastss (MAT_A, mat_elem_idx), mat_a1_0_8

.endm

.macro LOAD_MAT_B    // 每次装载矩阵B一行32个元素, 即B[k][n:n+32]

    // TODO 练习3: 请添加加载B[k][n:n+32]-->mat_b0_0_8, mat_b0_8_16, mat_b0_16_24, mat_b0_24_32的逻辑
    mov loop_k, %rax
    mul DIM_N
    mov %rax, temp_reg
    add loop_n, temp_reg
    mov temp_reg, mat_elem_idx
    shl $2, mat_elem_idx

    vmovups (MAT_B, mat_elem_idx), mat_b0_0_8
    vmovups 32(MAT_B, mat_elem_idx), mat_b0_8_16
    vmovups 64(MAT_B, mat_elem_idx), mat_b0_16_24
    vmovups 96(MAT_B, mat_elem_idx), mat_b0_24_32

.endm

.macro LOAD_MAT_C
    mov loop_m, %rax
    mul DIM_N
    mov %rax, temp_reg
    add loop_n, temp_reg

    // 装载矩阵C第一行的数据, 即C[m][n:n+32]
    mov temp_reg, mat_elem_idx
    shl $2, mat_elem_idx        // 左移，相当于乘4

    // TODO 练习3: 请添加加载C[m][n:n+32]-->mat_c0_0_8, mat_c0_8_16, mat_c0_16_24, mat_c0_24_32的逻辑
    vmovups (MAT_C, mat_elem_idx), mat_c0_0_8
    vmovups 32(MAT_C, mat_elem_idx), mat_c0_8_16
    vmovups 64(MAT_C, mat_elem_idx), mat_c0_16_24
    vmovups 96(MAT_C, mat_elem_idx), mat_c0_24_32

    // 装载矩阵C第二行的数据, 即C[m+1][n:n+32]
    mov temp_reg, mat_elem_idx
    add DIM_N, mat_elem_idx
    shl $2, mat_elem_idx        // 左移，相当于乘4

    // TODO 练习3: 请添加加载C[m+1][n:n+32]-->mat_c1_0_8, mat_c1_8_16, mat_c1_16_24, mat_c1_24_32的逻辑
    vmovups (MAT_C, mat_elem_idx), mat_c1_0_8
    vmovups 32(MAT_C, mat_elem_idx), mat_c1_8_16
    vmovups 64(MAT_C, mat_elem_idx), mat_c1_16_24
    vmovups 96(MAT_C, mat_elem_idx), mat_c1_24_32

.endm

.macro STORE_MAT_C
    // 保存矩阵C第一行的数据
    mov loop_m, %rax
    mul DIM_N
    mov %rax, temp_reg
    add loop_n, temp_reg

    // 保存矩阵C第一行的数据, 即C[m][n:n+32]
    mov temp_reg, mat_elem_idx
    shl $2, mat_elem_idx        // 左移，相当于乘4

    // TODO 练习3: 请添加保存mat_c0_0_8, mat_c0_8_16, mat_c0_16_24, mat_c0_24_32 --> C[m][n:n+32]的逻辑
    vmovups mat_c0_0_8, (MAT_C, mat_elem_idx)
    vmovups mat_c0_8_16, 32(MAT_C, mat_elem_idx)
    vmovups mat_c0_16_24, 64(MAT_C, mat_elem_idx)
    vmovups mat_c0_24_32, 96(MAT_C, mat_elem_idx)

    // 保存矩阵C第二行的数据, 即C[m+1][n:n+32]
    // TODO 练习3: 请添加保存mat_c1_0_8, mat_c1_8_16, mat_c1_16_24, mat_c1_24_32 --> C[m+1][n:n+32]的逻辑
    mov temp_reg, mat_elem_idx
    add DIM_N, mat_elem_idx
    shl $2, mat_elem_idx

    vmovups mat_c1_0_8, (MAT_C, mat_elem_idx)
    vmovups mat_c1_8_16, 32(MAT_C, mat_elem_idx)
    vmovups mat_c1_16_24, 64(MAT_C, mat_elem_idx)
    vmovups mat_c1_24_32, 96(MAT_C, mat_elem_idx)

.endm

.macro DO_COMPUTE      // 计算 C[m:m+2][n:n+32] += A[m:m+2][k] * B[k:k+8][n:n+32]

    // TODO 练习3: 请添加计算C[m:m+2][n:n+32] += A[m:m+2][k] * B[k:k+8][n:n+32]的逻辑
    vfmadd231ps mat_b0_0_8, mat_a0_0_8, mat_c0_0_8
    vfmadd231ps mat_b0_8_16, mat_a0_0_8, mat_c0_8_16
    vfmadd231ps mat_b0_16_24, mat_a0_0_8, mat_c0_16_24
    vfmadd231ps mat_b0_24_32, mat_a0_0_8, mat_c0_24_32

    vfmadd231ps mat_b0_0_8, mat_a1_0_8, mat_c1_0_8
    vfmadd231ps mat_b0_8_16, mat_a1_0_8, mat_c1_8_16
    vfmadd231ps mat_b0_16_24, mat_a1_0_8, mat_c1_16_24
    vfmadd231ps mat_b0_24_32, mat_a1_0_8, mat_c1_24_32

.endm


// Cache tiles: 64 rows x 64 columns. Each tile uses the existing
// 2x32 AVX/FMA microkernel, accumulating all K values in 8 YMM registers.
// As K is not split, every C value is loaded and stored once per call.
// The OpenMP wrapper pads arbitrary M/N to the 2x32 kernel contract.
.macro DO_GEMM
    test DIM_M, DIM_M
    jz AVX_DONE
    test DIM_N, DIM_N
    jz AVX_DONE
    test DIM_K, DIM_K
    jz AVX_DONE

    xor %rbx, %rbx                   // n0, 64-column tile start
AVX_N_TILE:
    xor %rbp, %rbp                   // m0, 64-row tile start
AVX_M_TILE:
    mov %rbx, loop_n
AVX_N_MICRO:
    mov %rbp, loop_m
AVX_M_MICRO:
    LOAD_MAT_C
    xor loop_k, loop_k
AVX_K:
    LOAD_MAT_A
    LOAD_MAT_B
    DO_COMPUTE
    inc loop_k
    cmp DIM_K, loop_k
    jl AVX_K
    STORE_MAT_C

    add $2, loop_m                   // microkernel MR=2
    cmp DIM_M, loop_m
    jge AVX_NEXT_N
    lea 64(%rbp), %rax
    cmp %rax, loop_m
    jl AVX_M_MICRO
AVX_NEXT_N:
    add $32, loop_n                  // microkernel NR=32
    cmp DIM_N, loop_n
    jge AVX_NEXT_M_TILE
    lea 64(%rbx), %rax
    cmp %rax, loop_n
    jl AVX_N_MICRO
AVX_NEXT_M_TILE:
    add $64, %rbp
    cmp DIM_M, %rbp
    jl AVX_M_TILE
    add $64, %rbx
    cmp DIM_N, %rbx
    jl AVX_N_TILE
AVX_DONE:
.endm



gemm_kernel_opt_avx:
    PUSHD
    GEMM_INIT
    DO_GEMM
    POPD
    vzeroupper
    ret

.section .note.GNU-stack,"",@progbits