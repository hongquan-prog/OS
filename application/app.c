#include "app.h"
#include "memory.h"
#include "utility.h"
#include "syscall.h"
#include "screen.h"

#define MAX_APP_NUM 16

static AppInfo s_app_to_run[MAX_APP_NUM] = {0};
static uint32 s_app_number = 0;
uint32 s_mutex = 0;
uint32 s_i = 0;

void TaskA()
{
    s_mutex = CreateMutex(STRICT);
    SetPrintPos(5, 0);
    PrintString("A Task:");
    
    for(s_i = 0; s_i < 50; s_i++)
    {
        EnterCritical(s_mutex);
        SetPrintPos(6, 0);
        PrintChar('A' + s_i % 26);
        Delay();
    }
    ExitCritical(s_mutex);
}
void TaskB()
{
    SetPrintPos(7, 0);
    PrintString("B Task:");
    EnterCritical(s_mutex);
    s_i = 0;
    while (1)
    {
        SetPrintPos(8, 0);
        PrintChar('0' + s_i);
        s_i = (s_i + 1) %10;
        Delay();
    }
    ExitCritical(s_mutex);
}

static void RegisterApp(const char *name, void (*tmain)(), byte priority)
{
    if (s_app_number < MAX_APP_NUM)
    {
        AppInfo *app = (AppInfo *)AddrOffset(s_app_to_run, s_app_number);
        app->name = name;
        app->tmain = tmain;
        app->priority = priority;
        s_app_number++;
    }
}

int AppMain()
{
    RegisterApp("A", TaskA, 255);
    RegisterApp("B", TaskB, 255);
    return 0;
}

AppInfo *GetAppToRun(uint32 index)
{
    AppInfo *ret = NULL;
    if (index < MAX_APP_NUM)
    {
        ret = (AppInfo *)AddrOffset(s_app_to_run, index);
    }
    return ret;
}

uint32 GetAppNum()
{
    return s_app_number;
}

