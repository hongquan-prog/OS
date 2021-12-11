#include "kernel.h"
#include "screen.h"
#include "task.h"
#include "interrupt.h"
#include "utility.h"
#include "memory.h"
#include "mutex.h"

void kmain()
{
    void (*AppModuleInit)() = (void*)BaseAddressOfApp;
    SetPrintPos(0, 38);
    PrintString("EOS");

    PrintString("\nGDT Entry:");
    PrintIntHex((uint32)g_gdt_info.entry);
    PrintString("\nGDT Size:");
    PrintIntDec(g_gdt_info.size);
    PrintString("\nIDT Entry:");
    PrintIntHex((uint32)g_idt_info.entry);
    PrintString("\nIDT Size:");
    PrintIntDec(g_idt_info.size);

    
    MemModuleInit((byte*)KernelHeapBaseAddr, HeapSize);
    MutexModuleInit();
    AppModuleInit();
    TaskModuleInit();
    InterruptModuleInit();
    // 将内核空间设置为只读
    ConfigPageTable();
    LaunchTask();
}