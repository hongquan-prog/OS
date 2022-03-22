#pragma once

#include "const.h"
#include "utility.h"
#include "type.h"

typedef struct _ListNode
{
    struct _ListNode *next;
    struct _ListNode *prev;
} ListNode;

typedef ListNode List;

#define List_ForEach(list, pos) for (pos = (list)->next; !IsEqual(list, pos); pos = pos->next)
#define List_Node(ptr, type, member) ContainerOf(ptr, type, member)

void List_Init(List *list);
void List_Add(List *list, ListNode *node);
void List_AddTail(List *list, ListNode *node);
void List_AddBefore(ListNode *before, ListNode *node);
void List_AddAfter(ListNode *after, ListNode *node);
void List_DelNode(ListNode *node);
void List_Replace(ListNode *old, ListNode *node);
int32 List_IsLast(List *list, ListNode *node);
bool List_IsEmpty(List *list);
