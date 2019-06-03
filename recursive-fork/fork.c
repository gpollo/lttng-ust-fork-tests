#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <pthread.h>

#ifndef DEFAULT_THREAD_COUNT
# define DEFAULT_THREAD_COUNT 6
#endif

#ifdef NO_LTTNG
# define tracepoint(a,b,c) printf(#a ":" #b ", pid=%u\n", c); fflush(stdout);
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

int main(int argc, char** argv)
{
#ifdef TEST_PTHREAD_ATFORK
	register_atfork();
#endif

	unsigned int thread_count = DEFAULT_THREAD_COUNT;
	if (argc > 1) {
		if(sscanf(argv[1], "%u", &thread_count) == 0) {
			fprintf(stderr, "sscanf: failed to parse UID\n");
			_exit(1);
		}
	}

	unsigned int child_count = thread_count;

	getchar();
	tracepoint(fork_test, process_spawned, getpid());

	for (unsigned int i = 1; i <= thread_count; i++) {
		pid_t pid = fork();
		if (pid < 0) {
			perror("fork() failed");
			break;
		}

		if (pid == 0) {
			tracepoint(fork_test, process_spawned, getpid());
			child_count = thread_count - i;
		} else {
			tracepoint(fork_test, child_spawned, getpid());
		}
	}

	for (unsigned int i = 0; i < child_count; i++) {
		pid_t child = wait(NULL);
		if (child < 0) {
			perror("wait() failed");	
			continue;
		}

		tracepoint(fork_test, child_terminated, getpid());
	}

	tracepoint(fork_test, process_terminated, getpid());

	return 0;
}
