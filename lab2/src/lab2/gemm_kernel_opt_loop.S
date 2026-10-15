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

/*
 * Lab2 exercise 3: 32x32 M/N cache tiling around the scalar SSE microkernel.
 * Traverse one narrow B-column block across a 32-row A/C block, reusing
 * nearby B cache lines. K is fully reduced for each C element, so C is
 * converted to float and stored only once; no rounding after partial K tiles.
 * Edge tiles handle arbitrary positive M, N and K.
 */
.macro DO_GEMM
    test DIM_M, DIM_M
    jz BLOCK_DONE
    test DIM_N, DIM_N
    jz BLOCK_DONE
    test DIM_K, DIM_K
    jz BLOCK_DONE

    mov DIM_N, %r15
    shl $2, %r15                     // stride between B[k][n] and B[k+1][n]
    xor %rbp, %rbp                    // n0: start column of 32-column tile
BLOCK_N:
    xor %rdx, %rdx                    // m0: start row of 32-row tile
BLOCK_M:
    mov %rdx, loop_m
BLOCK_ROW:
    mov %rbp, loop_n
BLOCK_COL:
    mov loop_m, mat_elem_idx
    imul DIM_N, mat_elem_idx
    add loop_n, mat_elem_idx
    cvtss2sd (MAT_C, mat_elem_idx, 4), %xmm0   // keep C[m][n] in double

    mov loop_m, %rax
    imul DIM_K, %rax
    lea (MAT_A, %rax, 4), %rax        // &A[m][0]
    mov loop_n, %rbx
    lea (MAT_B, %rbx, 4), %rbx        // &B[0][n]

    xor loop_k, loop_k
BLOCK_K:
    movss (%rax), %xmm1
    mulss (%rbx), %xmm1              // float product, matching reference
    cvtss2sd %xmm1, %xmm1
    addsd %xmm1, %xmm0
    add $4, %rax
    add %r15, %rbx
    inc loop_k
    cmp DIM_K, loop_k
    jl BLOCK_K

    cvtsd2ss %xmm0, %xmm0
    movss %xmm0, (MAT_C, mat_elem_idx, 4)

    inc loop_n
    cmp DIM_N, loop_n
    jge BLOCK_NEXT_ROW
    lea 32(%rbp), %rax
    cmp %rax, loop_n
    jl BLOCK_COL
BLOCK_NEXT_ROW:
    inc loop_m
    cmp DIM_M, loop_m
    jge BLOCK_NEXT_M_TILE
    lea 32(%rdx), %rax
    cmp %rax, loop_m
    jl BLOCK_ROW
BLOCK_NEXT_M_TILE:
    add $32, %rdx
    cmp DIM_M, %rdx
    jl BLOCK_M
    add $32, %rbp
    cmp DIM_N, %rbp
    jl BLOCK_N
BLOCK_DONE:
.endm

gemm_kernel_opt_loop:
    PUSHD
    GEMM_INIT
    DO_GEMM
    POPD
    ret

.section .note.GNU-stack,"",@progbits
