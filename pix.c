#define NUM 4
#define NAP 1
#define LIMIT 1000

#include "pix.h"

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <inttypes.h>
#include <pthread.h>

typedef struct Data
{
    uint32_t *ppi;
    uint64_t *pidx;
    uint64_t max;
} my_struct;

void *worker(void *data)
{
    my_struct *box = (my_struct *)(data);
    pix(box->ppi, box->pidx, box->max);
    return 0;
}

int main()
{
    pthread_t th[NUM];
    pthread_attr_t attr;
    int i, err;
    int *res;

    my_struct *data = malloc(sizeof(my_struct));
    data->max = 1000;
    data->ppi = malloc(data->max * sizeof(uint32_t));
    data->pidx = malloc(sizeof(uint64_t));

    printf("Process is creating threads\n");

    if ((err = pthread_attr_init(&attr)) != 0)
    {
        fprintf(stderr, "error");
        return 1;
    }

    if ((err = pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_JOINABLE)) != 0)
    {
        fprintf(stderr, "error");
        return 1;
    }

    for (i = 0; i < NUM; i++)
    {
        if ((err = pthread_create(&th[i], &attr, worker, data)) != 0)
        {
            fprintf(stderr, "error");
            return 1;
        }
    }

    printf("Main thread is waiting for workers\n");
    for (i = 0; i < NUM; i++)
    {
        if ((err = pthread_join(th[i], (void **)&res)) != 0)
        {
            fprintf(stderr, "error");
            return 1;
        }
        free(res);
    }

    for (unsigned int i = 0; i < data->max; i++)
    {
        printf("%08X\n", data->ppi[i]);
    }

    if ((err = pthread_attr_destroy(&attr)) != 0)
    {
        fprintf(stderr, "error");
        return 1;
    }
    return 0;
}

void pixtime(uint64_t clock_tick)
{
    fprintf(stderr, "%016lX\n", clock_tick);
}
