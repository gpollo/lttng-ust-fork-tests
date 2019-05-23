#include <unistd.h>
#include <stdio.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <pthread.h>

#ifndef THREAD_COUNT
# define THREAD_COUNT 5
#endif

#ifdef NO_LTTNG
# define tracepoint(a,b,c,str) printf(str "\n")
#else
# define TRACEPOINT_DEFINE
# include "tp_provider.h"
#endif

#define debug(str) tracepoint(fork_test, test, getpid(), str)

#ifdef TEST_PTHREAD_ATFORK
void before_fork(void)
{
	printf("handler_before_fork: pid=%u\n", getpid());
}

void after_fork_parent(void)
{
	printf("handler_after_fork_parent: ppid=%u pid=%u\n", getppid(), getpid());
}

void after_fork_child(void)
{
	printf("handler_after_fork_child: ppid=%u pid=%u\n", getppid(), getpid());
}

void register_atfork(void)
{
	if (pthread_atfork(before_fork, after_fork_parent, after_fork_child) < 0) {
		perror("pthread_atfork() failed");
	}
}
#endif

int main()
{
#ifdef TEST_PTHREAD_ATFORK
	register_atfork();
#endif

	int child_count = THREAD_COUNT;

	getchar();
	for (int i = 1; i <= THREAD_COUNT; i++) {
		pid_t pid = fork();
		if (pid < 0) {
			perror("fork() failed");
			break;
		}

		if (pid == 0) {
			debug("child spawned");
			child_count = THREAD_COUNT - i;
		}
	}

	for (int i = 0; i < child_count; i++) {
		pid_t child = wait(NULL);
		if (child < 0) {
			perror("wait() failed");	
			continue;
		}

		debug("child terminated");
	}

	return 0;
}
