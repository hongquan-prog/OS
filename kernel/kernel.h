#pragma once

#include "type.h"
#include "const.h"

typedef struct
{
    uint16 limit1;
    uint16 base1;
    byte base2;
    byte attr1;
    byte attr2_limit2;
    byte base3;
} Descriptor;

typedef struct
{
    Descriptor *const entry;
    const int32 size;
} GdtInfo;

typedef struct
{
    uint16 offset1;
    uint16 selector;
    byte dcount;
    byte attr;
    uint16 offset2;
} Gate;

typedef struct
{
    Gate *const entry;
    const int32 size;
} IdtInfo;

extern GdtInfo g_gdt_info;
extern IdtInfo g_idt_info;

bool SetDescValue(Descriptor *pDesc, uint32 base, uint32 limit, uint16 attr);
bool GetDescValue(Descriptor *pDesc, uint32 *pBase, uint32 *pLimit, uint16 *pAttr);
void ConfigPageTable();
