%include "common.asm"

global _start
global AppModuleInit

extern AppMain
extern GetAppNum
extern GetAppToRun
extern MemModuleInit

[section .text]
[bits 32]
_start:
AppModuleInit:
    push ebp
    mov ebp, esp

    mov dword [GetAppNumEntry], GetAppNum
    mov dword [GetAppToRunEntry], GetAppToRun

    push HeapSize
    push AppHeapBaseAddr
    call MemModuleInit
    add esp, 8

    call AppMain

    leave
    ret
