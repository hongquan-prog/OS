#include "interrupt.h"
#include "screen.h"
#include "task.h"
#include "mutex.h"

extern volatile Task *g_current_task;

void TimerHandler()
{
    Schedule();
    SendEOI(MASTER_EOI_PORT);
}

void SysCallHandler(uint32 type, uint32 cmd, uint32 param1, uint32 param2)
{
    switch (type)
    {
    case 0:
        KillTask();
        break;
    case 1:
        MutexModulHandler(cmd, param1, param2);
        break;
    default:
        break;
    }
}

void PageFaultHandler()
{
    SetPrintPos(GetCurrentRow() + 1, 0);
    PrintString("Page Fault: kill task ");
    PrintString((const char *)g_current_task->name);
    KillTask();
}

void SegmentFaultHandler()
{
    SetPrintPos(GetCurrentRow() + 1, 0);
    PrintString("Segment Fault: kill task ");
    PrintString((const char *)g_current_task->name);
    KillTask();
}
