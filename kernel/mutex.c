#include "mutex.h"
#include "memory.h"
#include "task.h"

typedef enum
{
    NORMAL,
    STRICT
} MutexType;

typedef struct
{
    ListNode head;
    uint32 lock;
    MutexType type;
} Mutex;

extern volatile Task *g_current_task;
List s_mutex_list = {0};

void MutexModuleInit()
{
    List_Init(&s_mutex_list);
}

Mutex *SysCreateMutex(MutexType type)
{
    Mutex *ret = Malloc(sizeof(Mutex));
    if (ret)
    {
        ret->type = type;
        ret->lock = 0;
        List_Add(&s_mutex_list, (ListNode *)ret);
    }
    return ret;
}

static bool IsMutexValid(Mutex *mutex)
{
    bool ret = false;
    ListNode *p = NULL;
    if (mutex)
    {
        List_ForEach(&s_mutex_list, p)
        {
            if (IsEqual(p, mutex))
            {
                ret = true;
                break;
            }
        }
    }
    return ret;
}

static void SysDestroyMutex(Mutex *mutex, uint32 ret)
{
    ListNode *p = NULL;
    if (mutex)
    {
        List_ForEach(&s_mutex_list, p)
        {
            if (IsEqual(p, mutex))
            {
                if (mutex->lock)
                {
                    *((uint32 *)ret) = false;
                }
                else
                {
                    List_DelNode(p);
                    Free(p);
                    *((uint32 *)ret) = true;
                }
                break;
            }
        }
    }
}

static void SysNormalEnterCritical(Mutex *mutex, uint32 wait)
{
    if (mutex->lock)
    {
        if (mutex->lock)
        {
            *((uint32 *)wait) = 1;
            MutexSchedule(WAIT);
        }
        else
        {
            mutex->lock = 1;
            *((uint32 *)wait) = 0;
        }
    }
}

static void SysStrictEnterCritical(Mutex *mutex, uint32 wait)
{
    if (mutex->lock)
    {
        if (!IsEqual(mutex->lock, g_current_task))
        {
            *((uint32 *)wait) = 1;
            MutexSchedule(WAIT);
        }
        else
            *((uint32 *)wait) = 0;
    }
    else
    {
        mutex->lock = (uint32)g_current_task;
        *((uint32 *)wait) = 0;
    }
}

static void SysEnterCritical(Mutex *mutex, uint32 wait)
{
    if (mutex && IsMutexValid(mutex))
    {
        switch (mutex->type)
        {
        case NORMAL:
            SysNormalEnterCritical(mutex, wait);
            break;
        case STRICT:
            SysStrictEnterCritical(mutex, wait);
            break;
        default:
            break;
        }
    }
}

static void SysNormalExitCritical(Mutex *mutex)
{
    mutex->lock = 0;
    MutexSchedule(NOTIFY);
}

static void SysStrictExitCritical(Mutex *mutex)
{
    if (IsEqual(mutex->lock, g_current_task))
    {
        mutex->lock = 0;
        MutexSchedule(NOTIFY);
    }
    else
    {
        KillTask();
    }
}

static void SysExitCritical(Mutex *mutex)
{
    if (mutex && IsMutexValid(mutex))
    {
        switch (mutex->type)
        {
        case NORMAL:
            SysNormalExitCritical(mutex);
            break;
        case STRICT:
            SysStrictExitCritical(mutex);
            break;
        default:
            break;
        }
    }
}

void MutexModulHandler(uint32 cmd, uint32 param1, uint32 param2)
{
    if (cmd == 0)
    {
        Mutex *mutex = SysCreateMutex(param2);
        *((uint32 *)param1) = (uint32)mutex;
    }
    else if (cmd == 1)
    {
        SysEnterCritical((Mutex *)param1, param2);
    }
    else if (cmd == 2)
    {
        SysExitCritical((Mutex *)param1);
    }
    else if (cmd == 3)
    {
        SysDestroyMutex((Mutex *)param1, param2);
    }
}