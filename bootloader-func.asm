;jmp指令一个字节，目标地址占一个字节，还差一个字节用nop占据
jmp short _start        
nop

define:
    exe_item_length equ 32
    exe_item_enrty equ BaseAddressOfStack - exe_item_length
    InitSPValue equ exe_item_enrty
    RootEntryOffset equ 19
    RootEntryLength equ 14
    FatTableEntry equ 1
    FatTableLength equ 9

header:
    BS_OEMName      db "hongquan"
    BPB_BytesPerSec dw 0x200
    BPB_SecPerClus  db 0x1
    BPB_ResvdSecCnt dw 0x1
    BPB_NumFATs     db 0x2
    BPB_RootEntCnt  dw 0xe0
    BPB_TotSec16    dw 0xb40
    BPB_Media       db 0xf0
    BPB_FATSz16     dw 0x9
    BPB_SecPerTrk   dw 0x12
    BPB_NumHeads    dw 0x2
    BPB_HiddSec     dd 0 
    BPB_TotSec32    dd 0
    BS_DrvNum       db 0
    BS_Reserved1    db 0
    BS_BootSig      db 0x29
    BS_VollD        dd 0xb0cb6425
    BS_VolLab       db "NO NAME    "   
    BS_FileSysType  db "FAT12   "

_start:
    jmp BootloaderMain

; LoadTarget(char* name,
;            uint16 name_len,
;            uint16 BaseAddressOfTarget,
;            uint16 BaseAddressOfTarget/0x10,
;            char* buf)

; 返回值 dx 不为0加载目标文件成功，否则失败
LoadTarget:
    mov bp, sp

    ; 读取14个扇区到内存中
    mov bx, [bp + 10] ;mov bx, TemporaryBuf
    mov ax, RootEntryOffset
    mov cx, RootEntryLength
    call ReadSector

    mov bp, sp
    ; 查找程序文件，目标地址bx
    mov si, [bp + 2];mov si, exe_name
    mov cx, [bp + 4];mov cx, exe_name_len
    mov dx, 0
    call FindEntry

    cmp dx, 0
    je LoadTargetEnd

    ; 拷贝找到的根目录项
    mov si, bx
    mov di, exe_item_enrty
    mov cx, exe_item_length
    call MemCpy

    ; 读取FAT表9个扇区到内存中
    mov bp, sp
    mov ax, FatTableLength
    mov cx, [BPB_BytesPerSec]
    mul cx
    mov bx, [bp + 6]; mov bx, BaseAddressOfTarget
    sub bx, ax

    mov ax, FatTableEntry
    mov cx, FatTableLength
    call ReadSector

    mov dx, [exe_item_enrty + 0x1a]
    mov si, [bp + 8]
    mov es, si
    mov si, 0
    call LoadExe
LoadTargetEnd:
    ret

; bx fat表首地址
; dx 第一簇所在位置
; si 程序加载地址
LoadExe:
    pusha
load_exe_loop:
    ; 小于0xFF7则拷贝，否则结束
    cmp dx, 0xff7
    jnb load_exe_end
    ; ax逻辑扇区号，cx拷贝数量
    mov ax, dx
    add ax, 31
    mov cx, 1
    push dx
    push bx
    ; si拷贝目标地址
    mov bx, si
    call ReadSector
    ; bx fat表位置
    ; cx 第一簇位置
    ; 返回值dx代表fat表项的值
    pop bx
    pop cx
    call FatVec
    ; 拷贝的目标地址加512
    add si, [BPB_BytesPerSec]
    cmp si, 0
    jne load_exe_loop
    ; si 等于0，es加上0x1000
    mov si, es
    add si, 0x1000
    mov es, si
    mov si, 0
    jmp load_exe_loop

load_exe_end:
    popa
    ret

; CX fat表下标
; BX fat表地址
; DX返回值 fat表项的值
; fat表下标除以2乘以3得到距fat表首地址的偏移
FatVec:
    push ax
    push cx
    push bp

    push cx
    ; CX中计算出fat表偏移首地址
    mov ax, cx
    shr ax, 1
    mov cx, 3
    mul cx
    mov cx, ax
    pop ax
    and ax, 1
    je fat_vec_even
    jmp fat_vec_odd
fat_vec_even:
    ; ret[j] = ((fat_table[i + 1] & 0xf) << 8) | fat_table[i]; 
    mov bp, cx
    add bp, bx
    mov dl, [bp + 1]
    and dl, 0xf
    shl dx, 8
    add cx, bx
    mov bp, cx
    mov dl, [bp]
    jmp fat_vec_end
fat_vec_odd:
    ; ret[j + 1] = (fat_table[i + 2] << 4) | (fat_table[i + 1] >> 4); 
    mov bp, cx
    add bp, bx
    mov dl, [bp + 2]
    mov dh, 0
    shl dx, 4
    mov bp, cx
    add bp, bx
    mov cl, [bp + 1]
    shr cl, 4
    or dl, cl
    jmp fat_vec_end
fat_vec_end:
    pop bp
    pop cx 
    pop ax
    ret


; es:bx 根目录起始地址
; ds:si 目标字符串
; cx 目标长度所在地址
; 返回值：dx 不为0存在，为0则不存在
; bx 为目标项地址
FindEntry:
    push di
    push bp
    push cx
    
    ; bp中存放长度所在地址
    mov dx, [BPB_RootEntCnt]
    mov bp, sp

find_entry_loop:
    cmp dx, 0
    je find_entry_failed
    mov di, bx
    mov cx, [bp]
    call MemCmp
    cmp cx, 0
    je find_entry_success
    add bx, 32
    dec dx
    jmp find_entry_loop
find_entry_failed:
find_entry_success:
    pop cx 
    pop bp
    pop di
    ret

; ds:si 源地址
; es:di 目标地址
; cx 比较长度
; cx 返回值，0相等，其他不相等
MemCmp:
    push si
    push di
    push ax
memcmp_start:
    cmp cx, 0
    je memcmp_equal
    mov al, [si]
    cmp al, [di]
    je memcmp_loop
    jmp memcmp_unequal
memcmp_loop:
    inc si
    inc di
    dec cx
    jmp memcmp_start
memcmp_unequal:
memcmp_equal:
    pop ax
    pop di
    pop si
    ret

; ds:si 源地址
; es:di 目标地址
; cx 拷贝长度
MemCpy:
    pusha
    ; 当源地址大于目标地址的时候，从头拷贝到尾，否则从尾拷贝到头
    cmp si, di
    ja begin_to_end
    add si, cx
    add di, cx
    dec si
    dec di
end_to_begin:
    cmp cx, 0
    jz memcpy_end
    mov al, [si]
    mov [di], al
    dec si
    dec di
    dec cx
    jmp end_to_begin
begin_to_end:
    cmp cx, 0
    jz memcpy_end
    mov al, [si]
    mov [di], al
    inc si
    inc di
    dec cx
    jmp begin_to_end
memcpy_end:
    popa
    ret


; 复位软盘
; 没有参数
ResetFloppy:
    pusha

    mov ah, 0x00
    mov dl, [BS_DrvNum]
    int 0x13

    popa
    ret

; 读取扇区
; ax 逻辑扇区号
; cx 读取的扇区数量
; es:bx 读取的目标地址
ReadSector:
    pusha

    call ResetFloppy
    push bx
    push cx

    ; 逻辑扇区除18
    mov bl, [BPB_SecPerTrk]
    div bl

    ; 将余数加1得到扇区号,放入CL
    mov cl, ah
    add cl, 1
    ; 将商右移1位得到柱面号，放入CH
    mov ch, al
    shr ch, 1
    ; 将商与1得到磁头号，放入DH
    mov dh, al
    and dh, 1
    ; DL放入驱动器号
    mov dl, [BS_DrvNum]
    ; 指定读取扇区数量,放入AL
    pop ax
    ; 恢复被修改的目标地址
    pop bx
    ; AH = 0x02
    mov ah, 2
; 读取失败重复读取
repeat_read:
    int 0x13
    jc repeat_read

    popa
    ret

; 打印字符串
; es:bp--->string address
; cx   --->string len
Print:
    pusha

    mov dx, 0
    mov ax, 0x1301
    mov bx, 0x07
    int 0x10

    popa
    ret