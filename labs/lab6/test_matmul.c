#define TESTING
#include "run.c"

#include <stdint.h>

static uint32_t rng_state = 0x6d2b79f5u;

static float next_test_float(void) {
    rng_state = rng_state * 1664525u + 1013904223u;
    return ((float)(rng_state & 0xffffu) - 32768.0f) / 32768.0f;
}

static int test_shape(int n, int d) {
    float *x = malloc((size_t)n * sizeof(float));
    float *w = malloc((size_t)n * (size_t)d * sizeof(float));
    float *expected = malloc((size_t)d * sizeof(float));
    float *actual = malloc((size_t)d * sizeof(float));
    if (!x || !w || !expected || !actual) {
        fprintf(stderr, "allocation failed for n=%d d=%d\n", n, d);
        free(x);
        free(w);
        free(expected);
        free(actual);
        return 0;
    }

    for (int j = 0; j < n; ++j) {
        x[j] = next_test_float();
    }
    for (size_t k = 0; k < (size_t)n * (size_t)d; ++k) {
        w[k] = next_test_float();
    }

    // Keep the reference's operation order identical to the original matmul.
    for (int i = 0; i < d; ++i) {
        float val = 0.0f;
        for (int j = 0; j < n; ++j) {
            val += w[i * n + j] * x[j];
        }
        expected[i] = val;
    }

    matmul(actual, x, w, n, d);
    int passed = memcmp(expected, actual, (size_t)d * sizeof(float)) == 0;
    if (!passed) {
        for (int i = 0; i < d; ++i) {
            if (memcmp(expected + i, actual + i, sizeof(float)) != 0) {
                fprintf(stderr, "FAIL n=%d d=%d row=%d expected=%.9g actual=%.9g\n",
                        n, d, i, expected[i], actual[i]);
                break;
            }
        }
    } else {
        printf("PASS n=%d d=%d\n", n, d);
    }

    free(x);
    free(w);
    free(expected);
    free(actual);
    return passed;
}

int main(void) {
    // Cover SIMD blocks, scalar tails, and representative Llama dimensions.
    static const int shapes[][2] = {
        {1, 1}, {7, 5}, {8, 8}, {9, 13}, {31, 17},
        {32, 32}, {33, 9}, {64, 288}, {288, 288},
        {768, 288}, {288, 768}, {1376, 512}
    };
    const size_t count = sizeof(shapes) / sizeof(shapes[0]);

    for (size_t i = 0; i < count; ++i) {
        if (!test_shape(shapes[i][0], shapes[i][1])) {
            return EXIT_FAILURE;
        }
    }

    printf("All %zu matmul cases passed bitwise comparison.\n", count);
    return EXIT_SUCCESS;
}
