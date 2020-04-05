#include "pix.h"

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>

int main()
{
    // extern pix(uint32_t * ppi, uint64_t * pidx, uint64_t max);
    uint32_t *ppi;
    uint64_t *pidx = malloc(sizeof(uint64_t));
    uint64_t max = 5;
    *pidx = 0;
    pix(ppi, pidx, max);
    //printf("%" PRIu64 "\n", *pidx);
    return 0;
}

void pixtime(uint64_t clock_tick)
{
    fprintf(stdout, "%016lX\n", clock_tick);
    // fprintf(stdout, "%" PRIu64 "\n", clock_tick);
}
