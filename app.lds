SECTIONS
{
    .text 0xF000:
    {
        *(.text)
        *(.rodata)
        *(.data)
        *(.bss)
    }
}