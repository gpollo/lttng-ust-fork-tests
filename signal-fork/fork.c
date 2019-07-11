#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <sys/wait.h>
#include <unistd.h>

#ifdef NO_LTTNG
# define tracepoint(a,b,c,str) printf("\r" str "\n"); fflush(stdout);
#else
# define TRACEPOINT_DEFINE
# include "tp_provider.h"
#endif

#define debug(str) tracepoint(fork_test, test, getpid(), str)

#define FORK_COUNT 10
#define CHILD_LIFETIME_US 1000

void sigint_handler(int signum)
{
	(void) signum;

	debug("signal handler");

	int child_count = 0;
	for (int i = 0; i < FORK_COUNT; i++) {
		int ret = fork();
		if (ret < 0) {
			perror("fork");
			continue;
		}

		if (ret == 0) {
			debug("process spawned");
			usleep(CHILD_LIFETIME_US);
			debug("process terminated");
			exit(0);
		} else {
			debug("child spawned");
			child_count++;
		}
	}

	for (int i = 0; i < child_count; i++) {
		if (wait(NULL) < 0) {
			perror("wait");
			continue;
		}
		debug("child terminated");
	}
}

int main()
{
	if (signal(SIGINT, sigint_handler) == SIG_ERR) {
		perror("signal");
		exit(1);
	}

	debug("process spawned");

	while(1) {
		if (usleep(2000000) < 0) {
			perror("usleep");
		} else {
			break;
		}
	}

	debug("process terminated");

	return 0;
}
