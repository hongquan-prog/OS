
#include "kernel.h"
#include "screen.h"

static int32 s_pos_row = 0;
static int32 s_pos_clumn = 0;
static char s_color = SCREEN_WHITE;

void ClearScreen()
{
    int32 clumn = 0;
    int32 row = 0;

    SetPrintPos(0, 0);

    for (row = 0; row < SCREEN_HEIGHT; row++)
    {
        for (clumn = 0; clumn < SCREEN_WIDTH; clumn++)
        {
            PrintChar(' ');
        }
    }

    SetPrintPos(0, 0);
}

bool SetPrintPos(byte row, byte clumn)
{
    bool ret = false;

    if ((row <= SCREEN_HEIGHT) && (clumn <= SCREEN_WIDTH))
    {
        unsigned short bx = SCREEN_WIDTH * row + clumn;

        ret = true;
        s_pos_row = row;
        s_pos_clumn = clumn;

        asm volatile(
            "movw %0,      %%bx\n"
            "movw $0x03D4, %%dx\n"
            "movb $0x0E,   %%al\n"
            "outb %%al,    %%dx\n"
            "movw $0x03D5, %%dx\n"
            "movb %%bh,    %%al\n"
            "outb %%al,    %%dx\n"
            "movw $0x03D4, %%dx\n"
            "movb $0x0F,   %%al\n"
            "outb %%al,    %%dx\n"
            "movw $0x03D5, %%dx\n"
            "movb %%bl,    %%al\n"
            "outb %%al,    %%dx\n"
            :
            : "r"(bx)
            : "ax", "bx", "dx");
    }

    return ret;
}

void SetPrintColor(PrintColor c)
{
    s_color = c;
}

int32 PrintChar(char c)
{
    int32 ret = false;

    if ((c == '\n') || (c == '\r'))
    {
        ret = SetPrintPos(s_pos_row + 1, 0);
    }
    else
    {
        byte row = s_pos_row;
        byte clumn = s_pos_clumn;

        if ((row <= SCREEN_HEIGHT) && (clumn <= SCREEN_WIDTH))
        {
            int32 edi = (SCREEN_WIDTH * row + clumn) * 2;
            char ah = s_color;
            char al = c;

            asm volatile(
                "movl %0,   %%edi\n"
                "movb %1,   %%ah\n"
                "movb %2,   %%al\n"
                "movw %%ax, %%gs:(%%edi)"
                "\n"
                :
                : "r"(edi), "r"(ah), "r"(al)
                : "ax", "edi");

            clumn++;

            if (clumn == SCREEN_WIDTH)
            {
                clumn = 0;
                row = row + 1;
            }

            ret = true;
        }

        SetPrintPos(row, clumn);
    }

    return ret;
}

int32 PrintString(const char *s)
{
    int32 ret = 0;

    if (s != NULL)
    {
        while (*s)
        {
            ret += PrintChar(*s++);
        }
    }
    else
    {
        ret = -1;
    }

    return ret;
}

int32 PrintIntHex(uint32 n)
{
    int32 i = 0;
    int32 ret = 0;

    ret += PrintChar('0');
    ret += PrintChar('x');

    for (i = 28; i >= 0; i -= 4)
    {
        int32 p = (n >> i) & 0xF;

        if (p < 10)
        {
            ret += PrintChar('0' + p);
        }
        else
        {
            ret += PrintChar('A' + p - 10);
        }
    }

    return ret;
}

int32 PrintIntDec(int32 n)
{
    int32 ret = 0;

    if (n < 0)
    {
        ret += PrintChar('-');

        n = -n;

        ret += PrintIntDec(n);
    }
    else
    {
        if (n < 10)
        {
            ret += PrintChar('0' + n);
        }
        else
        {
            ret += PrintIntDec(n / 10);
            ret += PrintIntDec(n % 10);
        }
    }

    return ret;
}

byte GetCurrentRow(void)
{
    return s_pos_row;
}

byte GetCurrentClumn(void)
{
    return s_pos_clumn;
}