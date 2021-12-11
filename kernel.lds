SECTIONS
{
    .text 0xB000:
    {
        *(.text)
        *(.data)
        *(.rodata)
        *(.bss)
    }
}