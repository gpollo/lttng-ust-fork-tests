#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <pthread.h>

#include <queue.c>

#ifndef DEFAULT_MAX_DEPTH
# define DEFAULT_MAX_DEPTH 2
#endif

#ifdef NO_LTTNG
# define tracepoint(a,b,c,...) printf(#a ":" #b ", pid=%u\n", c); fflush(stdout);
#else
# define TRACEPOINT_DEFINE
# include "tp_provider.h"
#endif

#define debug(str) tracepoint(fork_test, test, getpid(), str)

unsigned int do_exit = 0;

void sigint_handler(int signal)
{
	(void) signal;
	do_exit = 1;

	printf("\rSIGINT received\n");
}

/* blocks all signal except SIGINT and SIGCHLD */
void setup_signals(void)
{
	if (signal(SIGINT, sigint_handler) == SIG_ERR) {
		perror("signal() failed");
		_exit(1);
	}

	sigset_t sigset;
	if (sigfillset(&sigset) < 0) {
		perror("sigfillset() failed");
		_exit(1);
	}

	if (sigdelset(&sigset, SIGINT) < 0) {
		perror("sigdelset() failed");
		_exit(1);
	}

	if (sigdelset(&sigset, SIGCHLD) < 0) {
		perror("sigdelset() failed");
		_exit(1);
	}

	if (sigprocmask(SIG_SETMASK, &sigset, NULL) < 0) {
		perror("sigprocmask() failed");
		_exit(1);
	}
}

/* blocks all signal */
void setup_signals_child(void)
{
	sigset_t sigset;
	if (sigfillset(&sigset) < 0) {
		perror("sigfillset() failed");
		_exit(1);
	}

	if (sigprocmask(SIG_SETMASK, &sigset, NULL) < 0) {
		perror("sigprocmask() failed");
		_exit(1);
	}
}


unsigned int max_depth = DEFAULT_MAX_DEPTH;

struct pid_queue child_pids = PID_QUEUE_INIT;

void fork_loop(void)
{
	while (pid_queue_size(&child_pids) < max_depth) {
		pid_t pid = fork();
	
		if (pid < 0) {
			perror("fork() failed");
			break;
		}

		if (pid == 0) {
			tracepoint(fork_test, process_spawned, getpid());
			setup_signals_child();
			pid_queue_reset(&child_pids);
			do_exit = 1;
			max_depth--;
		} else {
			tracepoint(fork_test, child_spawned, getpid());
			if (pid_queue_push(&child_pids, pid) < 0) {
				perror("pid_queue_push");
			}
		}

		usleep(100000);
	}

	do {
		pid_t pid;
		if (pid_queue_pop(&child_pids, &pid) < 0) {
			break;
		}

		pid_t child = wait(NULL);
		if (child < 0) {
			perror("wait() failed");	
			continue;
		}

		tracepoint(fork_test, child_terminated, getpid(), pid);
	} while(do_exit);
}

int main(int argc, char** argv)
{
	if (argc > 1) {
		if(sscanf(argv[1], "%u", &max_depth) == 0) {
			fprintf(stderr, "sscanf: failed to parse maximum depth\n");
			_exit(1);
		}
	}

	setup_signals();
	getchar();

	tracepoint(fork_test, process_spawned, getpid());
	while (!do_exit) {
		fork_loop();
	}
	tracepoint(fork_test, process_terminated, getpid());

	return 0;
}
