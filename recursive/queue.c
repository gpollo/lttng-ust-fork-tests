#include <errno.h>
#include <stdlib.h>

#ifndef QUEUE_SIZE
# define QUEUE_SIZE 20
#endif

struct pid_queue {
	pid_t elements[QUEUE_SIZE];
	unsigned int head;
	unsigned int tail;
};

#define PID_QUEUE_INIT { \
	.head = 0,       \
	.tail = 0,       \
}

void pid_queue_reset(struct pid_queue* queue)
{
	queue->head = 0;
	queue->tail = 0;
}

unsigned int pid_queue_size(struct pid_queue* queue)
{
	return (queue->tail - queue->head + QUEUE_SIZE) % QUEUE_SIZE;
}

int pid_queue_push(struct pid_queue* queue, pid_t pid)
{
	if (queue->tail == (queue->head - 1 + QUEUE_SIZE) % QUEUE_SIZE) {
		errno = EAGAIN;
		return -errno;
	}

	queue->elements[queue->tail] = pid;
	queue->tail = (queue->tail + 1 + QUEUE_SIZE) % QUEUE_SIZE;

	return 0;
}

int pid_queue_pop(struct pid_queue* queue, pid_t* pid)
{
	if (queue->tail == queue->head) {
		errno = EAGAIN;
		return -errno;
	}

	pid[0] = queue->elements[queue->head];
	queue->head = (queue->head + 1 + QUEUE_SIZE) % QUEUE_SIZE;

	return 0;
}
