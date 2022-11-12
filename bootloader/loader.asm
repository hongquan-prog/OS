%include "bootloader-func.asm"
%include "common.asm"

org BaseAddressOfLoader

; 接口
Interface:
    BaseAddressOfStack equ BaseAddressOfLoader
    Kernel             db "KERNEL  BIN"
    KernelLen          equ $-Kernel
    App                db "APP     BIN"
    AppLen             equ $-App
    KernelError        db  "NO KERNEL"	
    KernelErrorLen     equ $-KernelError
    AppError           db  "NO APP"	
    AppErrorLen        equ $-AppError

jmp BootloaderMain

; ==========================================
;
;            GDT Segment 
;
; ==========================================
; begin of section .gdt
[section .gdt]
; 段描述符定义                        段基址           段界限               段属性
GDT_ENtry:              Descriptor    0,              0,                  0
; 32位保护模式下的描述符
CODE32_DESCRIPTOR:      Descriptor    0,      Code32SegmentLen-1,    DA_C + DA_32 + DA_DPL0
; 显存的描述符
GRAPHIC_DESCRIPTOR:     Descriptor 0xB8000,         0x7FFF,          DA_DRWA + DA_32 + DA_DPL0
; 平面模型下的代码段描述符
CODE32_FLAT_DESCRIPTOR: Descriptor    0,           0xfffff,          DA_C + DA_32 + DA_DPL0
; 平面模型下的数据段描述符
DATA32_FLAT_DESCRIPTOR: Descriptor    0,           0xfffff,          DA_DRW + DA_32 + DA_DPL0
; 局部段描述符
TASK_DESCRIPTOR:        Descriptor    0,              0,             DA_DPL0
; 任务状态段描述符
TSS_DESCRIPTOR:         Descriptor    0,              0,             DA_DPL0
; 页目录描述符
PAGE_DIR_DESCRIPTOR:    Descriptor  PageDirBase,      0,             DA_DRW + DA_LIMIT_4K + DA_DPL0
; 子页表描述符
PAGE_TABLE_DESCRIPTOR:  Descriptor PageTableBase,    1023,           DA_DRW + DA_LIMIT_4K + DA_DPL0
; GDT end
GDTLen equ $-GDT_ENtry
GDTPtr:
    dw GDTLen-1
    dd 0
; GDT 选择子
Code32Selector           equ (0x1 << 3) + SA_TIG + SA_RPL0
GraphicSelector          equ (0x2 << 3) + SA_TIG + SA_RPL0
Code32FlatSelector       equ (0x3 << 3) + SA_TIG + SA_RPL0
Data32FlatSelector       equ (0x4 << 3) + SA_TIG + SA_RPL0
PageDirSelector          equ (0x7 << 3) + SA_TIG + SA_RPL0
PageTableSelector        equ (0x8 << 3) + SA_TIG + SA_RPL0
; ==========================================
;
;            IDT Segment 
;
; ==========================================
[section .idt]
[bits 32]
IDT_SEGMENT:
; 中断描述符定义                       选择子                 偏移           参数个数        段属性
%rep 256
                   Gate          Code32Selector,     DefaultHandler,        0,       DA_386IGate
%endrep
IDTLen equ $-IDT_SEGMENT
IDTPtr:
    dw IDTLen-1
    dd 0
; ==========================================
;
;             Entry Segment 
;
; ==========================================
; 16位模式下设置进入32位的操作
[section .code16]
[bits 16]
BootloaderMain:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, InitSPValue

    ; 为32位代码段初始化GDT中段基址
    ; 当前处于16位模式下，一个地址表示方式：段地址：偏移地址
    mov esi, CODE32_SEGMENT
    mov edi, CODE32_DESCRIPTOR
    call InitDescItem

    ; 设置GDTPtr中描述符表的地址
    ; 当前处于16位模式下，一个地址表示方式：段地址：偏移地址
    mov eax, 0
    mov ax, ds
    shl eax, 4
    add eax, GDT_ENtry
    mov [GDTPtr + 2], eax

    ; 初始化中断描述符起始位置
    mov eax, 0
    mov ax, es
    shl eax, 4
    add eax, IDT_SEGMENT
    mov dword [IDTPtr + 2], eax

    ; 加载应用
    push word TemporaryBuf
    push word BaseAddressOfApp/0x10
    push word BaseAddressOfApp
    push word AppLen
    push word App
    call LoadTarget
    ; 恢复es寄存器的值
    mov ax, cs
    mov es, ax
    ; 恢复sp
    add sp, 10
    cmp dx, 0
    je AppErrOutput

    ; 加载内核
    push word TemporaryBuf
    push word BaseAddressOfKernel/0x10
    push word BaseAddressOfKernel
    push word KernelLen
    push word Kernel
    call LoadTarget
    ; 恢复es寄存器的值
    mov ax, cs
    mov es, ax
    ; 恢复sp
    add sp, 10
    cmp dx, 0
	je KernelErrOutput

    ; 将数据拷贝到内存
    call StoreGlobal

    ; 1、加载描述符表
    lgdt [GDTPtr]
    ; 2、关闭中断
    cli
    ; 加载中断描述符表
    lidt [IDTPtr]
    ; 设置IOPL为3，方便用户态和内核态使用中断
    pushf
    pop eax 
    or eax, 0x3000
    push eax
    popf
    ; 3、打开A20地址线
    in al, 0x92
    or al, 2
    out 0x92, al
    ; 4、进入保护模式
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    ; 5、跳转到32位保护模式
    ; dword 不加会被以16位立即数进行处理，超过16位会被截断
    jmp dword Code32Selector:0

StoreGlobal:
    push eax

    ; 写入gdt入口
    mov eax, GDT_ENtry
    mov [GdtEntry], eax
    ; 写入gdt长度
    mov eax, GDTLen / 8
    mov [GdtSize], eax
    ; 写入idt入口
    mov eax, IDT_SEGMENT
    mov [IdtEntry], eax
    ; 写入idt长度
    mov eax, IDTLen / 8
    mov [IdtSize], eax
    ; 运行任务的函数地址
    mov dword [RunTaskEntry], RunTask

    ; 初始化中断的函数地址
    mov dword [InitInterruptEntry], InitInterrupt
    ; 启动定时器的函数地址
    mov dword[EnableTimerEntry], EnableTimer
    ; 发送EOI的函数地址
    mov dword[SendEOIEntry], SendEOI
    ; 加载局部段描述符的函数地址
    mov dword[LoadTaskEntry], LoadTask
    pop eax
    ret
    
KernelErrOutput:	
    mov bp, KernelError
    mov cx, KernelErrorLen
	call Print
	jmp $

AppErrOutput:	
    mov bp, AppError
    mov cx, AppErrorLen
	call Print
	jmp $

; esi 段标签
; edi 段描述符标签
InitDescItem:
    pushad

    mov eax, 0
    mov ax, cs
    shl eax, 4
    add eax, esi
    mov [edi + 2], ax
    shr eax, 16
    mov [edi + 4], al
    mov [edi + 7], ah

    popad
    ret

; ==========================================
;
;             Global Function Segment 
;
; ==========================================
[section .gfunc]
[bits 32]
; 参数 任务数据结构指针
RunTask:
    push ebp
    mov ebp, esp

    ; 将sp指向结构体起始位置
    mov esp, [ebp + 8]

    ; 加载局部段描述符表和选择子
    lldt word [esp + 96]
    ltr word [esp + 98]
    ; 设置段寄存器值
    pop gs
    pop fs
    pop es
    pop ds
    ; 设置通用寄存器值
    popad
    ; 指向ip寄存器值
    add esp, 4
    ; iret返回的时候会从栈中恢复ip，cs，eflaf，esp，ss

    ; 开启定时器中断
    mov dx, MASTER_IMR_PORT
    in ax, dx
    %rep 5
    nop
    %endrep
    and ax, 0xfe
    out dx, al

    ; 启动页内存分页
    mov eax, cr0
    or eax, 0x80000000
    mov cr0, eax

    iret

LoadTask:
    push ebp
    mov ebp, esp

    mov eax, [ebp + 8]
    lldt word [eax + 96]
    leave
    ret


InitInterrupt:
    push ebp 
    mov ebp, esp

    push ax
    push dx

    ; 初始化8259A
    call Initilize8259A
    mov ax, 0xff
    mov dx, MASTER_IMR_PORT
    call WriteIMR
    mov ax, 0xff
    mov dx, SLAVE_IMR_PORT
    call WriteIMR

    pop dx
    pop ax

    pop ebp
    ret

; 使能定时器
EnableTimer:
    push ebp
    mov ebp, esp

    push ax
    push dx

    mov dx, MASTER_IMR_PORT
    call ReadIMR
    and ax, 0xfe
    call WriteIMR

    pop dx
    pop ax

    pop ebp
    ret

; 手动结束中断
SendEOI:
    push ebp
    mov ebp, esp

    mov edx, [ebp + 8]
    mov al, 0x20
    out dx, al
    call Delay

    pop ebp
    ret
; ==========================================
;
;            Static function Segment 
;
; ==========================================
[section .sfunc]
[bits 32]
; 延时
Delay:
    %rep 5
    nop
    %endrep
    ret
    
; 初始化8259A
Initilize8259A:
    push ax
    ;初始化主8259A
    mov al, 0x11
    out MASTER_ICW1_PORT, al
    call Delay

    mov al, 0x20
    out MASTER_ICW2_PORT, al
    call Delay

    mov al, 0x04
    out MASTER_ICW3_PORT, al
    call Delay

    mov al, 0x11
    out MASTER_ICW4_PORT, al
    call Delay

    ;初始化从8259A
    mov al, 0x11
    out SLAVE_ICW1_PORT, al
    call Delay

    mov al, 0x28
    out SLAVE_ICW2_PORT, al
    call Delay

    mov al, 0x02
    out SLAVE_ICW3_PORT, al
    call Delay

    mov al, 0x1
    out SLAVE_ICW4_PORT, al
    call Delay

    pop ax
    ret

; 写IMR的值
; al:写入值
; dx：8259A端口
WriteIMR:
    out dx, al
    call Delay
    ret
; 读IMR的值
; dx：8259A端口
; 返回值 ax:IMR寄存器的值
ReadIMR:
    in ax, dx
    call Delay
    ret
; ==========================================
;
;            Code32 Segment 
;
; ==========================================

[section .code32]
[bits 32]
CODE32_SEGMENT:
    ; 设置gs段寄存器值为显存选择子
    mov ax, GraphicSelector
    mov gs, ax

    ; 设置ss段寄存器值为堆栈选择子
    mov ax, Data32FlatSelector
    mov ss, ax
    mov esp, BaseAddressOfStack

    ; 设置ds段寄存器值为数据段选择子
    mov ax, Data32FlatSelector
    mov ds, ax
    mov es, ax
    mov fs, ax

    ; 建立页表
    call SetupPage

    jmp Code32FlatSelector:BaseAddressOfKernel

SetupPage:
    pushad
    push es

    ; 指定页目录起始地址
    mov ax, PageDirSelector
    mov es, ax
    mov edi, 0
    ; 指定循环次数，1024个子页表
    mov ecx, 1024
    mov eax, PageTableBase | PG_P | PG_USU | PG_RWW
    cld
SetupPageDirloop:
    ; 将eax放入edi目标地址edi，edi加4
    stosd 
    add eax, 4096
    loop SetupPageDirloop

    ; 指定页表起始地址
    mov ax, PageTableSelector
    mov es, ax
    mov edi, 0
    ; 指定循环次数，1024 * 1024
    mov ecx, 1024 * 1024
    mov eax, PG_P | PG_USU | PG_RWW
    cld
SetupPageTableloop:
    stosd 
    add eax, 4096
    loop SetupPageTableloop

    ; 开启内存分页
    mov eax, PageDirBase
    mov cr3, eax
    ; 在第一个任务执行前开启分页
    ; mov eax, cr0
    ; or eax, 0x80000000
    ; mov cr0, eax

    pop es
    popad
    ret

; 默认中断服务程序
DefaultHandleFunc:
    iret
DefaultHandler equ DefaultHandleFunc-$$
Code32SegmentLen equ $-CODE32_SEGMENT
TemporaryBuf db 0