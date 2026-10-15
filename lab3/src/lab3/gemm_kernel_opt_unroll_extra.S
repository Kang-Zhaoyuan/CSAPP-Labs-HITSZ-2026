.text
.p2align 2

#define MAT_C %rdi
#define MAT_A %rsi
#define MAT_B %r14
#define DIM_M %rcx
#define DIM_N %r8
#define DIM_K %r9
#define loop_m %r10
#define loop_k %r11
#define loop_n %r12
#define bidx %r13
#define cidx %r15

.macro PUSH_GPRS
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
.macro POP_GPRS
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

// Compute two adjacent outputs; keep A[m][k] in ST(0).
// Max five occupied x87 stack registers.
// bidx and cidx advance by two elements.
.macro GEMM_PAIR
    flds (MAT_B, bidx, 4)
    fmul %st(1), %st(0)
    flds 4(MAT_B, bidx, 4)
    fmul %st(2), %st(0)
    flds (MAT_C, cidx, 4)
    flds 4(MAT_C, cidx, 4)
    faddp %st, %st(2)
    faddp %st, %st(2)
    fstps 4(MAT_C, cidx, 4)
    fstps (MAT_C, cidx, 4)
    add $2, bidx
    add $2, cidx
.endm

// N-dimension unroll factor 4 or 8.
// Scalar tail handles odd N or N smaller than the factor.
.macro GEMM_KERNEL name, factor
    .globl \name
    .type \name, @function
\name:
    PUSH_GPRS
    mov %rdx, MAT_B
    xor loop_k, loop_k
GEMM_K\@:
    xor loop_m, loop_m
GEMM_M\@:
    xor loop_n, loop_n
    mov loop_m, %rax
    mul DIM_K
    add loop_k, %rax
    flds (MAT_A, %rax, 4)
GEMM_N\@:
    mov DIM_N, %rax
    sub loop_n, %rax
    cmp $\factor, %rax
    jb GEMM_TAIL\@

    mov DIM_N, %rax
    mul loop_k
    add loop_n, %rax
    mov %rax, bidx
    mov DIM_N, %rax
    mul loop_m
    add loop_n, %rax
    mov %rax, cidx
    .rept \factor / 2
        GEMM_PAIR
    .endr
    add $\factor, loop_n
    jmp GEMM_N\@

GEMM_TAIL\@:
    cmp DIM_N, loop_n
    jge GEMM_END_N\@
    mov DIM_N, %rax
    mul loop_k
    add loop_n, %rax
    flds (MAT_B, %rax, 4)
    fmul %st(1), %st(0)
    mov DIM_N, %rax
    mul loop_m
    add loop_n, %rax
    flds (MAT_C, %rax, 4)
    faddp %st, %st(1)
    fstps (MAT_C, %rax, 4)
    inc loop_n
    jmp GEMM_TAIL\@

GEMM_END_N\@:
    fstp %st(0)
    inc loop_m
    cmp DIM_M, loop_m
    jl GEMM_M\@
    inc loop_k
    cmp DIM_K, loop_k
    jl GEMM_K\@
    POP_GPRS
    ret
    .size \name, .-\name
.endm

GEMM_KERNEL gemm_kernel_opt_unroll4, 4
GEMM_KERNEL gemm_kernel_opt_unroll8, 8

.section .note.GNU-stack,"",@progbits
