#pragma once

#define AddrOffset(a, i)    ((void*)((uint32)(a) + (i) * sizeof(*(a))))
#define AddrIndex(b, a)  (((uint32)(b) - (uint32)(a))/sizeof(*(b)))

#define IsEqual(a, b)         \
({                            \
    unsigned ta = (unsigned)(a);\
    unsigned tb = (unsigned)(b);\
    !(ta - tb);               \
})

#define OffsetOf(type, member)  ((unsigned)&(((type*)0)->member))

#define ContainerOf(ptr, type, member)                  \
({                                                      \
      const typeof(((type*)0)->member)* __mptr = (ptr); \
      (type*)((char*)__mptr - OffsetOf(type, member));  \
})

char* StrCpy(char* dst, const char* src, int n);
void Delay();