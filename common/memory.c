#include "list.h"
#include "memory.h"

#define VM_HEAD_SIZE sizeof(VMemHead)
#define FM_ALLOC_SIZE 32
#define FM_NODE_SIZE sizeof(FMemNode)

typedef union _FMemNode FMemNode;

typedef struct
{
    byte data[FM_ALLOC_SIZE];
} FMemUnit;

union _FMemNode
{
    FMemNode *next;
    FMemUnit *ptr;
};

typedef struct
{
    FMemNode *head;
    FMemNode *manage_base_addr;
    FMemUnit *alloc_base_addr;
    uint32 total_item;
} FMemList;

typedef struct
{
    ListNode head;
    uint32 used;
    uint32 free;
    byte *ptr;
} VMemHead;

static FMemList s_fmem_list = {0};
static List s_vmem_list = {0};

void FMemInit(byte *mem, uint32 size)
{
    uint32 total_item = 0;
    FMemNode *p = NULL;
    int32 i = 0;

    if (mem)
    {
        total_item = size / (FM_ALLOC_SIZE + FM_NODE_SIZE);
        s_fmem_list.total_item = total_item;
        s_fmem_list.manage_base_addr = (FMemNode *)mem;
        s_fmem_list.alloc_base_addr = (FMemUnit *)(mem + (total_item * FM_NODE_SIZE));
        s_fmem_list.head = (FMemNode *)mem;

        for (i = 0, p = s_fmem_list.head; i < (total_item - 1); i++)
        {
            FMemNode *current = (FMemNode *)AddrOffset(p, i);
            FMemNode *next = (FMemNode *)AddrOffset(p, i + 1);
            current->next = next;
        }
        ((FMemNode *)AddrOffset(p, i))->next = NULL;
    }
}
void *FMemAlloc()
{
    void *ret = NULL;
    uint32 index = 0;
    FMemNode *node = NULL;

    if (s_fmem_list.head)
    {
        node = s_fmem_list.head;
        index = AddrIndex(node, s_fmem_list.manage_base_addr);
        ret = AddrOffset(s_fmem_list.alloc_base_addr, index);
        s_fmem_list.head = node->next;
        node->ptr = ret;
    }
    return ret;
}

bool FMemFree(void *ptr)
{
    bool ret = false;
    uint32 index = 0;
    FMemNode *node = NULL;

    if (ptr)
    {
        index = AddrIndex((FMemUnit *)ptr, s_fmem_list.alloc_base_addr);
        node = (FMemNode *)AddrOffset(s_fmem_list.manage_base_addr, index);
        if (index < s_fmem_list.total_item && IsEqual(node->ptr, ptr))
        {
            node->next = s_fmem_list.head;
            s_fmem_list.head = node;
            ret = true;
        }
    }
    return ret;
}

void VMemInit(byte *mem, uint32 size)
{
    if (mem)
    {
        List_Init((ListNode *)&s_vmem_list);
        VMemHead *head = (VMemHead *)mem;
        head->used = 0;
        head->free = size - VM_HEAD_SIZE;
        head->ptr = AddrOffset(head, 1);
        List_AddTail((ListNode *)&s_vmem_list, (ListNode *)head);
    }
}

void *VMemAlloc(uint32 size)
{
    VMemHead *ret = NULL;
    ListNode *p = NULL;
    uint32 alloc = VM_HEAD_SIZE + size;

    List_ForEach(&s_vmem_list, p)
    {
        VMemHead *current = (VMemHead *)p;

        if (current->free >= alloc)
        {
            byte *mem = (byte *)((uint32)current->ptr + (current->used + current->free) - alloc);
            ret = (VMemHead *)mem;
            ret->used = size;
            ret->free = 0;
            ret->ptr = AddrOffset(ret, 1);

            current->free -= alloc;

            List_AddAfter((ListNode *)current, (ListNode *)ret);

            break;
        }
    }

    return (ret) ? (ret->ptr) : ((void *)ret);
}

bool VMemFree(void *ptr)
{
    bool ret = false;
    ListNode *p = NULL;
    if (ptr)
    {

        List_ForEach(&s_vmem_list, p)
        {
            VMemHead *current = (VMemHead *)p;
            if (IsEqual(current->ptr, ptr))
            {
                VMemHead *prev = (VMemHead *)(current->head.prev);
                prev->free += current->used + current->free + VM_HEAD_SIZE;
                List_DelNode((ListNode *)current);
                ret = true;
                break;
            }
        }
    }

    return ret;
}

void MemModuleInit(byte *mem, uint32 size)
{
    byte *fmem = mem;
    uint32 fsize = size / 2;
    byte *vmem = AddrOffset(fmem, fsize);
    uint32 vsize = size - fsize;
    FMemInit(fmem, fsize);
    VMemInit(vmem, vsize);
}

void *Malloc(uint32 size)
{
    void *ret = NULL;
    if (size <= FM_ALLOC_SIZE)
        ret = FMemAlloc();
    if (!ret)
        ret = VMemAlloc(size);
    return ret;
}

void Free(void *ptr)
{
    if (ptr)
    {
        if (!FMemFree(ptr))
            VMemFree(ptr);
    }
}