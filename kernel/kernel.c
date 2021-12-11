#include "kernel.h"


GdtInfo g_gdt_info = {0};
IdtInfo g_idt_info = {0};

bool SetDescValue(Descriptor* pDesc, uint32 base, uint32 limit, uint16 attr)
{
    bool ret = false;
    if(ret = (pDesc != NULL))
    {
        pDesc->limit1 = limit & 0xffff;
        pDesc->base1 = base & 0xffff;
        pDesc->base2 = (base >> 16) & 0xff;
        pDesc->attr1 = attr & 0xff;
        pDesc->attr2_limit2 = ((attr >> 8) & 0xf0) | ((limit >> 16) & 0xf);
        pDesc->base3 = base >> 24;
    }
    return ret;
}

bool GetDescValue(Descriptor* pDesc, uint32* pBase, uint32* pLimit, uint16* pAttr)
{
    bool ret = false;

    if(ret = (pDesc && pDesc && pBase && pLimit && pAttr))
    {
        *pBase = (pDesc->base1) | (pDesc->base2 << 16) | (pDesc->base3 << 24);
        *pLimit = (pDesc->limit1) | ((pDesc->attr2_limit2 & 0xf) << 16);
        *pAttr = (pDesc->attr1) | ((pDesc->attr2_limit2 & 0xf0) << 8);
    }

    return ret;
}

void ConfigPageTable()
{
    int i = 0;
    uint32* page_table = (uint32*)PageTableBase;
    uint32 index = BaseAddressOfApp / 0x1000 - 1;
    for(i = 0; i <= index; i++)
    {
        uint32* addr = page_table + i;
        uint32 value = *addr;

        value = value & 0xfffffffd;
        *addr = value;
    }
}