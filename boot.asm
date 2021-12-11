

%include "bootloader-func.asm"
%include "common.asm"

org BaseAddressOfBoot

; 接口
Interface:
    BaseAddressOfStack equ BaseAddressOfBoot
    exe_name db "LOADER  BIN"
    exe_name_len equ $-exe_name
    err_str db  "NOLOADER"	
    err_str_len equ ($-err_str)

BootloaderMain:
    ; 初始化段寄存器
    mov ax, cs          
    mov ss, ax
    mov ds, ax
    mov es, ax
    ; 初始化栈顶指针
    mov sp, InitSPValue 

    push word TemporaryBuf
    push word BaseAddressOfLoader/0x10
    push word BaseAddressOfLoader
    push word exe_name_len
    push word exe_name
    call LoadTarget
    cmp dx, 0
	je ErrorOutput
	jmp BaseAddressOfLoader

ErrorOutput:	
    mov bp, err_str
    mov cx, err_str_len
	call Print
	jmp $


TemporaryBuf:
    ; $代表当前指令地址，$$代表当前段地址，times用于循环定义
    times 510-($-$$) db 0x00
    db 0x55,0xaa
    