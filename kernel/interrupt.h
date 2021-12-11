#pragma once

#include "kernel.h"

extern void (* InitInterrupt)();
extern void (* EnableTimer)();
extern void (* SendEOI)(uint32 port);

void InterruptModuleInit();
bool SetInterruptHandler(Gate* pGate, uint32 ifunc);
bool GetInterruptHandler(Gate* pGate, uint32* ifunc);