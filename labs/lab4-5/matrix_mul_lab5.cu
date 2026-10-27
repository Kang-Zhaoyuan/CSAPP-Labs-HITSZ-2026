#include <iostream>
#include <cstdio>
#include <cstdlib>
#include <climits>
#include <string>
#include <stdexcept>
#include <cuda_runtime.h>
#ifdef USE_CUBLAS
#include <cublas_v2.h>
#endif
#include <device_launch_parameters.h>
#include <cmath>
using namespace std;

#ifndef TILE_WIDTH
#define TILE_WIDTH 16
#endif
static_assert(TILE_WIDTH > 0 && TILE_WIDTH <= 32, "TILE_WIDTH must be 1..32");

#define CUDA_CHECK(call) do { \
  cudaError_t err = (call); \
  if (err != cudaSuccess) { \
    fprintf(stderr, "%s: %s\n", #call, cudaGetErrorString(err)); \
    exit(1); \
  } \
} while (0)
#ifdef USE_CUBLAS
#define CUBLAS_CHECK(call) do { \
  cublasStatus_t err = (call); \
  if (err != CUBLAS_STATUS_SUCCESS) { \
    fprintf(stderr, "%s: cuBLAS error %d\n", #call, (int)err); \
    exit(1); \
  } \
} while (0)
#endif

// Lab5: square matrices, zero-padding the incomplete boundary tiles.
__global__ void MatrixMulSharedMemKernel(float* A, float* B, float* C, int width)
{
  __shared__ float As[TILE_WIDTH][TILE_WIDTH];
  __shared__ float Bs[TILE_WIDTH][TILE_WIDTH];
  int tx = threadIdx.x, ty = threadIdx.y;
  int row = blockIdx.y * TILE_WIDTH + ty;
  int col = blockIdx.x * TILE_WIDTH + tx;
  float sum = 0.0f;
  for (int tile = 0; tile < width; tile += TILE_WIDTH) {
    As[ty][tx] = (row < width && tile + tx < width)
        ? A[row * width + tile + tx] : 0.0f;
    Bs[ty][tx] = (tile + ty < width && col < width)
        ? B[(tile + ty) * width + col] : 0.0f;
    __syncthreads();
    #pragma unroll
    for (int k = 0; k < TILE_WIDTH; ++k)
      sum += As[ty][k] * Bs[k][tx];
    // All threads must finish reading before the next tile overwrites As/Bs.
    __syncthreads();
  }
  if (row < width && col < width)
    C[row * width + col] = sum;
}


////////////////////////////////////////////////////////////////////////////////
//! Compute reference data set matrix multiply on CPU
//! C = A * B
//! @param C          reference data, computed but preallocated
//! @param A          matrix A as provided to device
//! @param B          matrix B as provided to device
//! @param hA         height of matrix A
//! @param wA         width of matrix A
//! @param wB         width of matrix B
////////////////////////////////////////////////////////////////////////////////
void
matrixMulCPU(float *C, const float *A, const float *B, unsigned int hA, unsigned int wA, unsigned int wB)
{
    for (unsigned int i = 0; i < hA; ++i)
        for (unsigned int j = 0; j < wB; ++j)
        {
            double sum = 0;

            for (unsigned int k = 0; k < wA; ++k)
            {
                double a = A[i * wA + k];
                double b = B[k * wB + j];
                sum += a * b;
            }

            C[i * wB + j] = (float)sum;
        }
}

int printDiff(float *data1, float *data2, int width, int height, int iListLength, float fListTol)
{
    printf("Listing first %d differences (abs/rel tolerance %.6f)...\n", iListLength, fListTol);
    int i,j,k;
    int error_count=0;

    for (j = 0; j < height; j++)
    {
        for (i = 0; i < width; i++)
        {
            k = j * width + i;
            float fDiff = fabs(data1[k] - data2[k]);

            if (!isfinite(data2[k]) || fDiff > fListTol * (1.0f + fabs(data1[k])))
            {
                if (error_count < iListLength)
                {
                    printf("    Loc(%d,%d)\tCPU=%.5f\tGPU=%.5f\tDiff=%.6f\n", i, j, data1[k], data2[k], fDiff);
                }

                error_count++;
            }
        }
    }

    printf(" \n  Total Errors = %d\n", error_count);
    return error_count;
}

void getArg(int argc, char* argv[], int &size, int &check)
{
  if (argc != 3)
  {
    cerr << "Usage: " << argv[0] << " <check_enable> <size>\n";
    cerr << "\tcheck_enable: 1 to enable result checking\n";
    cerr << "\tsize: size of the matrix\n";
    exit(1);
  }

  int val1, val2;
  try
  {
    size_t pos1, pos2;
    val1 = stoi(argv[1], &pos1);
    val2 = stoi(argv[2], &pos2);
    if (argv[1][pos1] || argv[2][pos2] || (val1 != 0 && val1 != 1) ||
        val2 <= 0 || (long long)val2 * val2 > INT_MAX)
      throw invalid_argument("invalid dimensions");
  }
  catch (const exception& e)
  {
    cerr << "ERROR: check must be 0/1; size must be a positive integer with size^2 <= INT_MAX\n";
    exit(1);
  }

  check = val1;
  size = val2;
}



int main(int argc, char* argv[])
{
  int size, check;
  getArg(argc, argv, size, check);

  int m = size, n = size, k = size;

  // Host and device arrays
  float *h_M, *h_N, *d_M, *d_N;
  float *h_P, *d_P;

  size_t sizeM = (size_t)m * k * sizeof(float);
  size_t sizeN = (size_t)k * n * sizeof(float);
  size_t sizeP = (size_t)m * n * sizeof(float);

  // Allocate host memory
  h_M = (float*) malloc(sizeM);
  h_N = (float*) malloc(sizeN);
  h_P = (float*) malloc(sizeP);
  float *reference = (float *)malloc(sizeP);

  if (!h_M || !h_N || !h_P || !reference) {
    fprintf(stderr, "Host allocation failed\n");
    return 1;
  }

  // Allocate device memory
  CUDA_CHECK(cudaMalloc(&d_M, sizeM));
  CUDA_CHECK(cudaMalloc(&d_N, sizeN));
  CUDA_CHECK(cudaMalloc(&d_P, sizeP));

  // Distinct, non-symmetric inputs also catch indexing/transposition mistakes.
  for (int i = 0; i < m * n; ++i) {
    h_M[i] = ((i * 1LL * 17 % 29) - 14) / 16.0f;
    h_N[i] = ((i * 1LL * 13 % 31) - 15) / 16.0f;
  }

  // Copy data from CPU to GPU
  CUDA_CHECK(cudaMemcpy(d_M, h_M, sizeM, cudaMemcpyHostToDevice));
  CUDA_CHECK(cudaMemcpy(d_N, h_N, sizeN, cudaMemcpyHostToDevice));

  // Timing records
  cudaEvent_t start,stop;
  CUDA_CHECK(cudaEventCreate(&start));
  CUDA_CHECK(cudaEventCreate(&stop));

  // Launch kernel 定义grid&block
  dim3 grid((n + TILE_WIDTH - 1) / TILE_WIDTH, (m + TILE_WIDTH - 1) / TILE_WIDTH);
  dim3 block(TILE_WIDTH, TILE_WIDTH);

  int nIter = 5;
#ifdef USE_CUBLAS
  cublasHandle_t handle;
  CUBLAS_CHECK(cublasCreate(&handle));
#endif
  const float alpha = 1.0f;
  const float beta  = 0.0f;
#ifdef USE_CUBLAS
  printf("Method: cublas, N=%d, TILE_WIDTH=%d\n", size, TILE_WIDTH);
#else
  printf("Method: shared, N=%d, TILE_WIDTH=%d\n", size, TILE_WIDTH);
#endif
  // Warm up once; exclude setup and transfers from kernel timing.
  for (int j = -1; j < nIter; ++j) {
    if (j == 0) {
      CUDA_CHECK(cudaDeviceSynchronize());
      CUDA_CHECK(cudaEventRecord(start, 0));
    }
#ifdef USE_CUBLAS
    // Row-major C=A*B equals column-major C^T=B^T*A^T.
    CUBLAS_CHECK(cublasSgemm(handle, CUBLAS_OP_N, CUBLAS_OP_N,
        n, m, k, &alpha, d_N, n, d_M, k, &beta, d_P, n));
#else
    MatrixMulSharedMemKernel<<<grid, block>>>(d_M, d_N, d_P, m);
    CUDA_CHECK(cudaGetLastError());
#endif
  }

  CUDA_CHECK(cudaEventRecord(stop, 0));
  CUDA_CHECK(cudaEventSynchronize(stop));
  float msecPerMatrixMul;
  CUDA_CHECK(cudaEventElapsedTime(&msecPerMatrixMul, start, stop));
  msecPerMatrixMul /= nIter;
  printf("Kernel Elapsed Time: %.3f ms\n", msecPerMatrixMul);

  // Compute and print the performance
  double flopsPerMatrixMul = 2.0 * (double)m * (double)n * (double)k;
  double gigaFlops = (flopsPerMatrixMul * 1.0e-9f) / (msecPerMatrixMul / 1000.0f);
  printf("Performance= %.2f GFlop/s, Time= %.3f msec, Size= %.0f Ops\n",
		  gigaFlops,
		  msecPerMatrixMul,
		  flopsPerMatrixMul);

  // Copy data from GPU to CPU
  CUDA_CHECK(cudaMemcpy(h_P, d_P, sizeP, cudaMemcpyDeviceToHost));

  int errors = 0;
  // compute reference solution
  if (check == 1)
  {
    printf("Computing result using host CPU...");
    matrixMulCPU(reference, h_M, h_N, m, k, n);
    printf("done.\n");
    errors = printDiff(reference, h_P, n, m, 100, 1.0e-5f);
  }

  free(reference);
  free(h_P);
  free(h_M);
  free(h_N);
  CUDA_CHECK(cudaFree(d_P));
  CUDA_CHECK(cudaFree(d_M));
  CUDA_CHECK(cudaFree(d_N));
#ifdef USE_CUBLAS
  CUBLAS_CHECK(cublasDestroy(handle));
#endif

  CUDA_CHECK(cudaEventDestroy(start));
  CUDA_CHECK(cudaEventDestroy(stop));
  return errors ? 1 : 0;
}
