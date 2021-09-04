//
//  csp.h
//  WXRCoobjc
//
//  Created by wangxiaorui19 on 2021/8/30.
//

#ifndef csp_h
#define csp_h

#include <stdio.h>
#include "coroutine.h"

typedef enum channel_op channel_op_t;

typedef struct chan_alt chan_alt_t;
typedef struct co_channel co_channel_t;
typedef struct alt_queue alt_queue_t;
typedef struct chan_queue chan_queue_t;

enum channel_op {
    CHANNEL_SEND = 1,
    CHANNEL_RECEIVE,
};

struct chan_alt {
    co_channel_t *channel;
    coroutine_t *task;
    void *value;
    chan_alt_t *pre;
    chan_alt_t *next;
    channel_op_t op;
    int canblock;
};

struct alt_queue {
    chan_alt_t *head;
    chan_alt_t *tail;
    unsigned int count;
};

struct chan_queue {
    void * arr;
    unsigned int elementsize; // 元素内存大小
    unsigned int count; // 实际元素个数
    unsigned int size; // arr的个数
    unsigned int expandsize; // 一次扩展个数
    unsigned int head;
    unsigned int tail;
};

struct co_channel {
    chan_queue_t buffer;
    alt_queue_t recqueue;
    alt_queue_t sendqueue;
    pthread_mutex_t lock;
};

// create
co_channel_t * chancreate(int elemsize,int bufsize);
// send
// recive
int channbrecv(co_channel_t *c, void *v);

void chanfree(co_channel_t *c);

#endif /* csp_h */
