//
//  csp.c
//  WXRCoobjc
//
//  Created by wangxiaorui19 on 2021/8/30.
//

#include "csp.h"
#define otherop(op)    (CHANNEL_SEND+CHANNEL_RECEIVE-(op))

static alt_queue_t *_chanarray(co_channel_t *c, uint op) {
    switch (op) {
        case CHANNEL_SEND:
            return &(c->sendqueue);
            break;
        case CHANNEL_RECEIVE:
            return &(c->recqueue);
        default:
            return nil;;
    }
}

static int _altcanexec(chan_alt_t *a) {
    alt_queue_t *altqueue;
    co_channel_t *c = a->channel;
    if (c->buffer.size == 0) {
        altqueue = _chanarray(c, otherop(a->op));
        return altqueue && altqueue->count;
    } else if (c->buffer.expandsize) {
        switch (a->op) {
            case CHANNEL_SEND:
                return 1;
            case CHANNEL_RECEIVE:
                return c->buffer.count > 0;
            default:
                return 0;
        }
    } else {
        switch (a->op) {
            case CHANNEL_SEND:
                return c->buffer.count < c->buffer.size;
            case CHANNEL_RECEIVE:
                return c->buffer.count > 0;
            default:
                return 0;
        }
    }
    
    return 0;
}

static int _chanalt(chan_alt_t *a) {
    coroutine_t *t = coroutine_self();
    a->task = t;
    co_channel_t *c = a->channel;
//    chanlock(c);
    
    return 0;
}

static int _chanop(co_channel_t *c, int op, void *p, int canblock){
    chan_alt_t *a = calloc(1, sizeof(chan_alt_t));
    a->channel = c;
    a->op = op;
    a->value = p;
    a->canblock = canblock;
    a->pre = NULL;
    a->next = NULL;
    
    int ret = _chanalt(a);
    free(a);
    return ret;
}

static void queueinit(chan_queue_t *q, int elemsize, int bufsize, int expandsize, void *buf){
    q->elementsize = elemsize;
    q->size = bufsize;
    q->expandsize = expandsize;
    
    if (expandsize) { // ?
        if (bufsize > 0) {
            q->arr = malloc(bufsize * elemsize);
        }
    } else {
        if (buf) {
            q->arr = buf;
        }
    }
}

co_channel_t * chancreate(int elemsize,int bufsize) {
    co_channel_t *c;
    if (bufsize < 0) {
        c = calloc(1, sizeof(co_channel_t));
    } else {
        c = calloc(1, sizeof(co_channel_t) + bufsize * elemsize);
    }
    
    if (bufsize < 0) {
        queueinit(&c->buffer, elemsize, 16, 16, NULL);// ?
    } else {
        queueinit(&c->buffer, elemsize, bufsize, 0, (void *)(c+1)); // ?
    }
    
    return c;
}

void chanfree(co_channel_t *c){
    if (c == NULL) {
        return;
    }
//    chancancelallalt(c);
    if (c->buffer.expandsize) {
        free(c->buffer.arr);
    }
    free(c);
}

int channbrecv(co_channel_t *c, void *v) {
    return _chanop(c, CHANNEL_RECEIVE, v, NO);
}



