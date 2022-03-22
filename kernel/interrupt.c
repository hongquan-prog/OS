#include "interrupt.h"
#include "utility.h"
#include "interrupt_handler.h"

void (*InitInterrupt)() = NULL;
void (*EnableTimer)() = NULL;
void (*SendEOI)(uint32 port) = NULL;

void InterruptModuleInit()
{
    SetInterruptHandler(AddrOffset(g_idt_info.entry, 0x0D), (uint32)SegmentFaultHandlerEntry);
    SetInterruptHandler(AddrOffset(g_idt_info.entry, 0x0E), (uint32)PageFaultHandlerEntry);
    SetInterruptHandler(AddrOffset(g_idt_info.entry, 0x20), (uint32)TimerHandlerEntry);
    SetInterruptHandler(AddrOffset(g_idt_info.entry, 0x80), (uint32)SysCallHandlerEntry);

    InitInterrupt();
}

bool SetInterruptHandler(Gate *pGate, uint32 ifunc)
{
    bool ret = false;
    if (pGate && (ifunc != 0))
    {
        ret = true;
        pGate->offset1 = ifunc & 0xffff;
        pGate->selector = GDT_CODE32_FLAT_SELECTOR;
        pGate->dcount = 0;
        pGate->offset2 = ifunc >> 16;
        pGate->attr = DA_386IGate + DA_DPL3;
    }
    return ret;
}

bool GetInterruptHandler(Gate *pGate, uint32 *ifunc)
{
    bool ret = false;
    if (pGate && ifunc)
    {
        ret = true;
        *ifunc = pGate->offset1 | (pGate->offset2 << 16);
    }
    return ret;
}
