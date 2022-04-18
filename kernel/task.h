#pragma once

#include "kernel.h"
#include "queue.h"

typedef struct
{
    uint32 gs;
    uint32 fs;
    uint32 es;
    uint32 ds;
    uint32 edi;
    uint32 esi;
    uint32 ebp;
    uint32 kesp;
    uint32 ebx;
    uint32 edx;
    uint32 ecx;
    uint32 eax;
    uint32 error_code;
    uint32 eip;
    uint32 cs;
    uint32 eflags;
    uint32 esp;
    uint32 ss;
} RegValue;

typedef struct
{
    uint32 previous;
    uint32 esp0;
    uint32 ss0;
    uint32 unused[22];
    uint16 reserved;
    uint16 iomb;
} TSS;

typedef struct
{
    RegValue rv;
    Descriptor ldt[3];
    uint16 ldtSelector;
    uint16 tssSelector;
    void (*tmain)();
    uint32 id;
    uint16 current;
    uint16 total;
    char name[8];
    byte *stack;
} Task;

typedef struct
{
    QueueNode head;
    Task task;
} TaskNode;

typedef enum
{
    WAIT,
    NOTIFY
} MutexAction;

extern void (*RunTask)(volatile Task *pt);
extern void (*LoadTask)(volatile Task *pt);

void TaskModuleInit();
void LaunchTask();
void Schedule();
void KillTask();
void MutexSchedule(MutexAction action);