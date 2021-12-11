#include "syscall.h"

void Exit()
{
    asm volatile(
        "movl   $0, %eax\n"
        "int    $0x80\n"
    );
}

uint32 CreateMutex(MutexType type)
{
    volatile uint32 ret = 0;

    asm volatile(
        "movl   $1, %%eax\n"
        "movl   $0, %%ebx\n"
        "movl   %0, %%ecx\n"
        "movl   %1, %%edx\n"
        "int    $0x80\n"
        :
        :"r"(&ret), "r"(type)
        :"eax", "ebx", "ecx", "edx"
    );
    return ret;
}
void EnterCritical(uint32 mutex)
{
    volatile uint32 wait = 0;
    do{
        asm volatile(
        "movl   $1, %%eax\n"
        "movl   $1, %%ebx\n"
        "movl   %0, %%ecx\n"
        "movl   %1, %%edx\n"
        "int    $0x80\n"
        :
        :"r"(mutex), "r"(&wait)
        :"eax", "ebx", "ecx", "edx"
        );
    }while(wait);
}

void ExitCritical(uint32 mutex)
{
    asm volatile(
        "movl   $1, %%eax\n"
        "movl   $2, %%ebx\n"
        "movl   %0, %%ecx\n"
        "int    $0x80\n"
        :
        :"r"(mutex)
        :"eax", "ebx", "ecx", "edx"
    );
}

bool DestroyMutex(uint32 mutex)
{
    uint32 ret = 0;
    asm volatile(
        "movl   $1, %%eax\n"
        "movl   $3, %%ebx\n"
        "movl   %0, %%ecx\n"
        "movl   %1, %%edx\n"
        "int    $0x80\n"
        :
        :"r"(mutex), "r"(&ret)
        :"eax", "ebx", "ecx", "edx"
    );

    return (ret != 0);
}