#pragma once

#include "type.h"

typedef struct app
{
    const char *name;
    void (*tmain)();
    byte priority;
} AppInfo;
