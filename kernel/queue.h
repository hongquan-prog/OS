#pragma once

#include "list.h"

typedef ListNode QueueNode;

typedef struct
{
    ListNode head;
    int32 length;
} Queue;

void Queue_Init(Queue *queue);
bool Queue_IsEmpty(Queue *queue);
bool Queue_IsContained(Queue *queue, QueueNode *node);
void Queue_Add(Queue *queue, QueueNode *node);
QueueNode *Queue_Front(Queue *queue);
QueueNode *Queue_Remove(Queue *queue);
int32 Queue_Length(Queue *queue);
void Queue_Rotate(Queue *queue);
