#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>

// uint64_t quick_pow_hex(uint64_t pow, uint64_t m)
// {
//     if (pow == 0)
//     {
//         return 1;
//     }
//     if (pow % 2 == 0)
//     {
//         uint64_t temp = quick_pow_hex(pow / 2, m);
//         return (temp * temp) % m;
//     }
//     return (16 * quick_pow_hex(pow - 1, m)) % m;
// }

/* Iterative Function to calculate (x^y) in O(logy) */
uint64_t power(uint64_t y, uint64_t m)
{
    uint64_t res = 1; // Initialize result
    uint64_t x = 16;
    while (y > 0)
    {
        // If y is odd, multiply x with result
        if (y & 1)
            res = (res * x) % m;

        // n must be even now
        y = y >> 1;      // y = y/2
        x = (x * x) % m; // Change x to x^2
    }
    return res;
}

int main()
{
    printf("%lu ", power(16, 5));

    // printf("%" PRIu64 "\n", quick_pow_hex(a, 3));
    return 0;
}