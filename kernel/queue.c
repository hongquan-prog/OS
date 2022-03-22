#include "queue.h"

void Queue_Init(Queue *queue)
{
    List_Init((List *)queue);

    queue->length = 0;
}

bool Queue_IsEmpty(Queue *queue)
{
    return List_IsEmpty((List *)queue);
}

bool Queue_IsContained(Queue *queue, QueueNode *node)
{
    ListNode *pos = NULL;
    bool ret = false;

    List_ForEach((List *)queue, pos)
    {
        if (IsEqual(pos, node))
        {
            ret = true;
            break;
        }
    }

    return ret;
}

void Queue_Add(Queue *queue, QueueNode *node)
{
    List_AddTail((List *)queue, node);

    queue->length++;
}

QueueNode *Queue_Front(Queue *queue)
{
    return queue->head.next;
}

QueueNode *Queue_Remove(Queue *queue)
{
    QueueNode *ret = NULL;

    if (queue->length > 0)
    {
        ret = queue->head.next;

        List_DelNode(ret);

        queue->length--;
    }

    return ret;
}

int32 Queue_Length(Queue *queue)
{
    return queue->length;
}

void Queue_Rotate(Queue *queue)
{
    if (queue->length > 0)
    {
        QueueNode *node = Queue_Remove(queue);

        Queue_Add(queue, node);
    }
}
