#pragma once

#define SCREEN_WIDTH    80
#define SCREEN_HEIGHT   25

typedef enum
{
    SCREEN_GRAY   = 0x07,
    SCREEN_BLUE   = 0x09,
    SCREEN_GREEN  = 0x0A,
    SCREEN_RED    = 0x0C,
    SCREEN_YELLOW = 0x0E,
    SCREEN_WHITE  = 0x0F
} PrintColor;

void ClearScreen();
bool  SetPrintPos(byte x, byte y);
void SetPrintColor(PrintColor c);
int PrintChar(char c);
int PrintString(const char* s);
int PrintIntDec(int32 n);
int PrintIntHex(uint32 n);
byte GetCurrentRow(void);
byte GetCurrentClumn(void);