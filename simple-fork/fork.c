#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>

#define TRACEPOINT_DEFINE
#include "tp_provider.h"

//#define tracepoint(namespace, event, ...) printf(#namespace ":" #event "\n"); fflush(stdin);

int main()
{
	tracepoint(fork_test, process_spawned, getpid());

	for(int i = 0; i < 3; i++) {
		pid_t pid = fork();
		if (pid < 0) {
			perror("fork");
			break;
		}

		if (pid) {
			tracepoint(fork_test, child_spawned, getpid(), pid);
			pid_t child = wait(NULL);
			if (child < 0) {
				perror("wait");
			}
			tracepoint(fork_test, child_terminated, getpid(), pid);	
		} else {
			tracepoint(fork_test, process_spawned, getpid());
			usleep(10);
			break;
		}
	}

	tracepoint(fork_test, process_terminated, getpid());

	return 0;
}
