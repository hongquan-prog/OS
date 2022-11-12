%include "common.asm"

global _start
global PageFaultHandlerEntry
global TimerHandlerEntry
global SysCallHandlerEntry
global SegmentFaultHandlerEntry

extern g_gdt_info
extern g_idt_info
extern g_current_task

extern kmain
extern ClearScreen
extern RunTask
extern LoadTask
extern InitInterrupt
extern EnableTimer
extern SendEOI

extern TimerHandler
extern SysCallHandler
extern PageFaultHandler
extern SegmentFaultHandler

%macro BeginFSR 0
    cli
    pushad
    push ds
    push es 
    push fs
    push gs

    ; 指定数据段选择子
    mov si, ss
    mov ds, si
    mov es, si
    ; 指定内核栈顶指针
    mov esp, BaseAddressOfLoader
%endmacro

%macro BeginISR 0
    cli
    sub esp, 4

    pushad
    push ds
    push es 
    push fs
    push gs

    ; 指定数据段选择子
    mov si, ss
    mov ds, si
    mov es, si
    ; 指定内核栈顶指针
    mov esp, BaseAddressOfLoader
%endmacro


%macro EndISR 0
    mov esp, [g_current_task]
    pop gs
    pop fs
    pop es
    pop ds

    popad

    add esp, 4
    iret
%endmacro



[section .text]
[bits 32]
_start:
    mov ebp, 0
    call InitGlobal
    call ClearScreen
    call kmain
    jmp $

InitGlobal:
    push ebp
    mov ebp, esp
    ; 设置全局段描述符表位置和个数
    mov eax, [GdtEntry]
    mov [g_gdt_info], eax
    mov eax, [GdtSize]
    mov [g_gdt_info + 4], eax
    ; 设置中断描述符表位置和个数
    mov eax, [IdtEntry]
    mov [g_idt_info], eax
    mov eax, [IdtSize]
    mov [g_idt_info + 4], eax
    ; 设置函数RunTask的值
    mov eax, [RunTaskEntry]
    mov [RunTask], eax
    ; 初始化中断的函数地址
    mov eax, [InitInterruptEntry]
    mov [InitInterrupt], eax
    ; 启动定时器的函数地址
    mov eax, [EnableTimerEntry]
    mov [EnableTimer], eax
    ; 发送EOI的入口地址
    mov eax, [SendEOIEntry]
    mov [SendEOI],eax
    ; 加载局部段描述符的入口地址
    mov eax, [LoadTaskEntry]
    mov [LoadTask],eax
    
    pop ebp
    ret

TimerHandlerEntry:
BeginISR
    call TimerHandler
EndISR

SysCallHandlerEntry:
BeginISR
    push edx
    push ecx
    push ebx
    push eax
    call SysCallHandler
    pop eax
    pop ebx
    pop ecx
    pop edx
EndISR

PageFaultHandlerEntry:
BeginFSR
    call PageFaultHandler
EndISR

SegmentFaultHandlerEntry:
BeginFSR
    call SegmentFaultHandler
EndISR