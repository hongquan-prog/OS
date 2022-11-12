BaseAddressOfBoot   equ 0x7c00
BaseAddressOfLoader equ 0x9000
BaseAddressOfKernel equ 0xB000
BaseAddressOfApp    equ 0xF000

; 堆地址
HeapBaseAddr        equ 0x70000
HeapSize            equ 0x20000
KernelHeapBaseAddr  equ HeapBaseAddr
AppHeapBaseAddr     equ HeapBaseAddr - HeapSize

; 页表地址
PageDirBase         equ HeapBaseAddr + HeapSize
PageTableBase       equ PageDirBase + 0x1000

; 传递给内核的信息
BaseAddressOfSharedMem equ 0xA000
GdtEntry               equ BaseAddressOfSharedMem + 0
GdtSize                equ BaseAddressOfSharedMem + 4
IdtEntry               equ BaseAddressOfSharedMem + 8
IdtSize                equ BaseAddressOfSharedMem + 12
RunTaskEntry           equ BaseAddressOfSharedMem + 16
InitInterruptEntry     equ BaseAddressOfSharedMem + 20
EnableTimerEntry       equ BaseAddressOfSharedMem + 24
SendEOIEntry           equ BaseAddressOfSharedMem + 28
LoadTaskEntry          equ BaseAddressOfSharedMem + 32
GetAppToRunEntry       equ BaseAddressOfSharedMem + 36
GetAppNumEntry         equ BaseAddressOfSharedMem + 40
; PIC-8259A Ports 
MASTER_ICW1_PORT                        equ     0x20
MASTER_ICW2_PORT                        equ     0x21
MASTER_ICW3_PORT                        equ     0x21
MASTER_ICW4_PORT                        equ     0x21
MASTER_OCW1_PORT                        equ     0x21
MASTER_OCW2_PORT                        equ     0x20
MASTER_OCW3_PORT                        equ     0x20

SLAVE_ICW1_PORT                         equ     0xA0
SLAVE_ICW2_PORT                         equ     0xA1
SLAVE_ICW3_PORT                         equ     0xA1
SLAVE_ICW4_PORT                         equ     0xA1
SLAVE_OCW1_PORT                         equ     0xA1
SLAVE_OCW2_PORT                         equ     0xA0
SLAVE_OCW3_PORT                         equ     0xA0

MASTER_EOI_PORT                         equ     0x20
MASTER_IMR_PORT                         equ     0x21
MASTER_IRR_PORT                         equ     0x20
MASTER_ISR_PORT                         equ     0x20

SLAVE_EOI_PORT                          equ     0xA0
SLAVE_IMR_PORT                          equ     0xA1
SLAVE_IRR_PORT                          equ     0xA0
SLAVE_ISR_PORT                          equ     0xA0

; 段属性
DA_32          equ 0x4000
DA_LIMIT_4K    equ 0x8000
DA_DR          equ 0x90
DA_DRW         equ 0x92
DA_DRWA        equ 0x93
DA_C           equ 0x98
DA_CR          equ 0x9A
DA_CCO         equ 0x9C
DA_CCOR        equ 0x9E

; 页属性
PG_P     equ    1    ; 页存在属性位
PG_RWR   equ    0    ; R/W 属性位值, 读/执行
PG_RWW   equ    2    ; R/W 属性位值, 读/写/执行
PG_USS   equ    0    ; U/S 属性位值, 系统级
PG_USU   equ    4    ; U/S 属性位值, 用户级

; 段特权级
DA_DPL0  equ 0x00
DA_DPL1  equ 0x20
DA_DPL2  equ 0x40
DA_DPL3  equ 0x60

; 特殊属性
DA_LDT       equ    0x82
DA_TaskGate  equ    0x85	; 任务门类型值
DA_386TSS    equ	0x89	; 可用 386 任务状态段类型值
DA_386CGate  equ	0x8C	; 386 调用门类型值
DA_386IGate  equ	0x8E	; 386 中断门类型值
DA_386TGate  equ	0x8F	; 386 陷阱门类型值

; 选择子属性
SA_RPL0  equ 0
SA_RPL1  equ 1
SA_RPL2  equ 2
SA_RPL3  equ 3

SA_TIG   equ 0
SA_TIL   equ 4

; 描述符
; 段基址,段界限，段属性
%macro Descriptor 3                        
    dw %2 & 0xffff                         ; 段界限1
    dw %1 & 0xffff                         ; 段基址1
    db (%1 >> 16) & 0xff                   ; 段基址2
    dw ((%2 >> 8) & 0xf00) | (%3 & 0xf0ff) ; 属性1 + 段界限2 + 属性2
    db (%1 >> 24) & 0xff                   ; 段基址3
%endmacro

; 调用门
%macro Gate 4                        
    dw %2 & 0xffff                         ; 偏移地址1
    dw %1                                  ; 选择子
    dw (%3 & 0x1f) | ((%4 << 8) & 0xff00)  ; 属性
    dw ((%2 >> 16) & 0xffff)               ; 偏移地址2
%endmacro