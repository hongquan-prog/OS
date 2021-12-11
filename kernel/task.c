#include "task.h"
#include "utility.h"
#include "app.h"

#define MAX_RUNNING_TASK 2
#define MAX_TASK_NUM 4
#define MAX_READY_TASK (MAX_TASK_NUM - MAX_RUNNING_TASK)
#define PID_BASE 0x10
#define MAX_TASK_BUF_NUM (MAX_TASK_NUM + 1)
#define MAX_TIME_SLICE 260

static TSS s_tss = {0};
volatile Task *g_current_task = NULL;
static TaskNode s_task_buf[MAX_TASK_NUM] = {0};
static TaskNode s_idle_task = {0};
static s_app_to_run_index = 0;
static uint32 s_pid = PID_BASE;

static Queue s_running_task_queue = {0};
static Queue s_ready_task_queue = {0};
static Queue s_free_task_queue = {0};
static Queue s_wait_task_queue = {0};

void (* const RunTask)(volatile Task* pt) = NULL;
void (* const LoadTask)(volatile Task* pt) = NULL;

AppInfo* (*GetAppToRun)(uint32 index) = NULL;
uint32 (*GetAppNum)() = NULL;


static void IdleTask()
{   
    // 此处不能写任何全局变量，因为他们属于内核空间，IdleTask只能读不能写，否则就会出发异常
    while (1);
}

void TaskEntry()
{
    if(g_current_task)
    {
        g_current_task->tmain();
    }
    // 特权级为0时候才能销毁任务 （系统调用）
    asm volatile(
        "movl   $0, %eax\n"
        "int    $0x80\n"
    );
}

void TaskInit(Task* task, uint32 id, const char* name, void (*task_entry), byte priority)
{
    task->rv.cs = LDT_CODE32_SELECTOR;
    task->rv.gs = LDT_GRAPHIC_SELECTOR;
    task->rv.ss = LDT_DATA32_SELECTOR;
    task->rv.ds = LDT_DATA32_SELECTOR;
    task->rv.es = LDT_DATA32_SELECTOR;
    task->rv.fs = LDT_DATA32_SELECTOR;
    // 指向栈顶
    task->rv.esp = (uint32)(task->stack) + AppStackSize;
    task->rv.eip = (uint32)TaskEntry;
    task->tmain = task_entry;
    task->id = id;
    task->current = 0;
    task->total = MAX_TIME_SLICE - priority;
    // 设置IOPL为3和屏蔽中断
    task->rv.eflags = 0x3202;
    // 初始化局部段描述符表
    SetDescValue(AddrOffset(task->ldt, LDT_GRAPHIC_INDEX), 0xB8000, 0x7FFF, DA_DRWA + DA_32 + DA_DPL3);
    SetDescValue(AddrOffset(task->ldt, LDT_CODE32_INDEX), 0, KernelHeapBaseAddr - 1, DA_C + DA_32 + DA_DPL3);
    SetDescValue(AddrOffset(task->ldt, LDT_DATA32_INDEX), 0, KernelHeapBaseAddr - 1, DA_DRW + DA_32 + DA_DPL3);
    // 初始化任务状态段和局部段选择子
    task->ldtSelector = GDT_LDT_TASK_SELECTOR;
    task->tssSelector = GDT_TSS_SELECTOR;
    StrCpy(task->name, name, sizeof(task->name) - 1);
}

static void PrepareForRun(volatile Task* pt)
{
    pt->current++;
    s_tss.ss0 = GDT_DATA32_FLAT_SELECTOR;
    s_tss.esp0 = (uint32)&pt->rv + sizeof(pt->rv);
    s_tss.iomb = sizeof(TSS);
    // 初始化局部段描述符
    SetDescValue(AddrOffset(g_gdt_info.entry, GDT_LDT_TASK_INDEX), (uint32)&pt->ldt, sizeof(pt->ldt)-1, DA_LDT + DA_DPL0);
}

static void CreateTask()
{
    uint32 num = GetAppNum();
    while((s_app_to_run_index < num) && 
    (Queue_Length(&s_ready_task_queue) < MAX_READY_TASK))
    {
        AppInfo* ai = GetAppToRun(s_app_to_run_index);
        TaskNode* tn = (TaskNode*)Queue_Remove(&s_free_task_queue);
        if(ai && tn)
        {
            TaskInit(&(tn->task), s_pid++, ai->name, ai->tmain, ai->priority);
            Queue_Add(&s_ready_task_queue, (QueueNode*)tn);
            s_app_to_run_index++;
        }
        else
        {
            break;
        }
    }
}

static void ReadyToRunning()
{
    if(Queue_Length(&s_ready_task_queue) < MAX_READY_TASK)
    {
        CreateTask();
    }
    while(Queue_Length(&s_ready_task_queue) && (Queue_Length(&s_running_task_queue) < MAX_RUNNING_TASK))
    {
        QueueNode* qn = Queue_Remove(&s_ready_task_queue);
        ((TaskNode*)qn)->task.current = 0;
        Queue_Add(&s_running_task_queue, qn);
    }
}

static void CheckRunningTask()
{
    if(!Queue_Length(&s_running_task_queue))
    {
        Queue_Add(&s_running_task_queue, (QueueNode *)&s_idle_task);
    }
    else if(Queue_Length(&s_running_task_queue) > 1)
    {
        if(IsEqual(Queue_Front(&s_running_task_queue), (QueueNode*)&s_idle_task))
        {
            Queue_Remove(&s_running_task_queue);
        }
    }
}


void TaskModuleInit()
{
    int i = 0;
    byte* p = (byte*)(AppHeapBaseAddr - (AppStackSize * MAX_TASK_BUF_NUM));
    for(i = 0; i < MAX_TASK_NUM; i++)
    {
        ((TaskNode*)AddrOffset(s_task_buf, i))->task.stack = (byte*)(p + (AppStackSize * i));
    }
    s_idle_task.task.stack = p + (AppStackSize * i);

    GetAppToRun = (void*)(*((uint32 *)GetAppToRunEntry));
    GetAppNum = (void*)(*((uint32 *)GetAppNumEntry));

    // 初始化队列
    Queue_Init(&s_running_task_queue);
    Queue_Init(&s_free_task_queue);
    Queue_Init(&s_ready_task_queue);
    Queue_Init(&s_wait_task_queue);
    // 空闲Tasknode入队
    for(i = 0; i < MAX_TASK_NUM; i++)
    {
        Queue_Add(&s_free_task_queue, (QueueNode *)AddrOffset(s_task_buf, i));
    }
    // 初始化任务状态段描述符
    SetDescValue(AddrOffset(g_gdt_info.entry, GDT_TSS_INDEX), (uint32)&s_tss, sizeof(s_tss)-1, DA_386TSS + DA_DPL0);
    // 初始化Idle
    TaskInit(&s_idle_task.task, 0, "Idle", IdleTask, 255);
    // 将任务从就绪队列添加到运行队列
    ReadyToRunning();
    // 检查如果有任务就删除Idle，没有就添加Idle
    CheckRunningTask();
}

void LaunchTask()
{
    g_current_task = &((TaskNode *)Queue_Front(&s_running_task_queue))->task;
    PrepareForRun(g_current_task);
    RunTask(g_current_task);
}

static RunningToReady()
{
    if(Queue_Length(&s_running_task_queue) > 0)
    {
        TaskNode* node = (TaskNode*)Queue_Front(&s_running_task_queue);
        if(!IsEqual(node, &s_idle_task))
        {
            if(IsEqual(node->task.current, node->task.total))
            {
                Queue_Remove(&s_running_task_queue);
                Queue_Add(&s_ready_task_queue, (QueueNode*)node);
            }
        }
    }
}

static void WaitToReady()
{
    while(Queue_Length(&s_wait_task_queue) > 0)
    {
        TaskNode* node = (TaskNode*)Queue_Front(&s_wait_task_queue);
        Queue_Remove(&s_wait_task_queue);
        Queue_Add(&s_ready_task_queue, (QueueNode*)node);
    }
}

static void RunningToWait()
{
    if(Queue_Length(&s_running_task_queue) > 0)
    {
        TaskNode* node = (TaskNode*)Queue_Front(&s_running_task_queue);
        if(!IsEqual(node, &s_idle_task))
        {
            Queue_Remove(&s_running_task_queue);
            Queue_Add(&s_wait_task_queue, (QueueNode*)node);
        }
    }
}

void MutexSchedule(MutexAction action)
{
    switch (action)
    {
    case NOTIFY:
        WaitToReady();
        break;
    case WAIT:
        RunningToWait();
        ReadyToRunning();
        CheckRunningTask();
        Queue_Rotate(&s_running_task_queue);
        g_current_task = &((TaskNode *)Queue_Front(&s_running_task_queue))->task;
        PrepareForRun(g_current_task);
        LoadTask(g_current_task);
        break;
    default :
        break;
    }
}

void Schedule()
{
    RunningToReady();
    ReadyToRunning();
    CheckRunningTask();
    Queue_Rotate(&s_running_task_queue);
    g_current_task = &((TaskNode *)Queue_Front(&s_running_task_queue))->task;
    PrepareForRun(g_current_task);
    LoadTask(g_current_task);
}

void KillTask()
{
    QueueNode* qn = Queue_Remove(&s_running_task_queue);
    Queue_Add(&s_free_task_queue, qn);
    Schedule();
}

