#pragma once

#include "type.h"


void MemModuleInit(byte* mem, uint32 size);
void* Malloc(uint32 size);
void Free(void* ptr);