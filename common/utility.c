#include "utility.h"

void Delay()
{
    int32 i = 0;
    int32 j = 0;
    for (i = 0; i < 1000; i++)
    {
        for (j = 0; j < 1000; j++)
        {
            asm volatile("nop\n");
        }
    }
}

char *StrCpy(char *dst, const char *src, int32 n)
{
    char *ret = dst;
    int32 i = 0;

    for (i = 0; src[i] && (i < n); i++)
    {
        dst[i] = src[i];
    }

    dst[i] = 0;

    return ret;
}