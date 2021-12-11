#pragma once

#include "type.h"

typedef enum
{
    NORMAL,
    STRICT
}MutexType;

void Exit();
uint32 CreateMutex(MutexType type);
void EnterCritical(uint32 mutex);
void ExitCritical(uint32 mutex);
bool DestroyMutex(uint32 mutex);