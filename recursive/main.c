#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <pthread.h>
#include <unistd.h>

#include "queue.c"

#ifndef FORK_COUNT
# define FORK_COUNT 20
#endif

#ifndef MAX_DEPTH
# define MAX_DEPTH 3
#endif

#ifdef NO_LTTNG
# define tracepoint(a,b,c,...) printf(#a ":" #b ", pid=%u\n", c); fflush(stdout);
#else
# define TRACEPOINT_DEFINE
# include "tp_provider.h"
#endif

static char* progname = NULL;
static pid_t main_process;

unsigned int do_exit = 0;

void sigint_handler(int signal)
{
	(void) signal;
	do_exit = 1;

	printf("\r%s: SIGINT received\n", progname);
}

/* blocks all signal except SIGINT */
void setup_signals(void)
{
	if (main_process != getpid()) {
		return;
	}

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


unsigned int max_depth = MAX_DEPTH;

struct pid_queue child_pids = PID_QUEUE_INIT;

void spawn_childs(void)
{
	while (pid_queue_size(&child_pids) < max_depth) {
		setup_signals_child();
		pid_t pid = fork();
	
		if (pid < 0) {
			perror("fork() failed");
			break;
		}

		if (pid == 0) {
			tracepoint(fork_test, process_spawned, getpid());
			pid_queue_reset(&child_pids);

			/* childs always exit after waiting for their childs */
			do_exit = 1;

			/* prevent a fork bomb by decrementing level count in child */
			max_depth--;
		} else {
			setup_signals();
			tracepoint(fork_test, child_spawned, getpid(), pid);
			if (pid_queue_push(&child_pids, pid) < 0) {
				perror("pid_queue_push");
			}
		}
	}
}

pid_t wait_no_block(pid_t pid)
{
	return waitpid(pid, NULL, WNOHANG);
}

pid_t wait_block(pid_t pid)
{
	fprintf(stderr, "waitpid() may deadlock by waiting on pid=%u\n", pid);
	pid_t ret_pid = waitpid(pid, NULL, 0);
	fprintf(stderr, "waitpid() didn't deadlock by waiting on pid=%u\n", pid);
	return ret_pid;
}

void wait_childs(void)
{
	do {
		pid_t child_pid, exit_pid;
		if (pid_queue_pop(&child_pids, &child_pid) < 0) {
			break;
		}

		/* we do our best to detect deadlock */
		unsigned int try_count = 0;
retry_waitpid:
		if (try_count < 100) {
			exit_pid = wait_no_block(child_pid);
		} else {
			/* having the deadlock will allow debugging with GDB */
			exit_pid = wait_block(child_pid);
		}

		/* only WNOHANG returns 0 */
		if (exit_pid == 0) {
			try_count++;
			sleep(1);
			goto retry_waitpid;
		} else if (exit_pid < 0) {
			perror("waitpid() failed");
			continue;
		}

		if (child_pid != exit_pid) {
			fprintf(stderr, "waitpid() returned pid=%u, but "
				"expected pid=%u\n", exit_pid, child_pid);
		}

		tracepoint(fork_test, child_terminated, getpid(), child_pid);
	} while(do_exit);
}

void fork_loop(void)
{
	spawn_childs();
	wait_childs();
}

int main(int argc, char** argv)
{
	progname = argv[0];
	main_process = getpid();

	if (argc > 1) {
		if(sscanf(argv[1], "%u", &max_depth) == 0) {
			fprintf(stderr, "sscanf: failed to parse maximum depth\n");
			_exit(1);
		}
	}

	setup_signals();
	getchar();

	tracepoint(fork_test, process_spawned, getpid());
	for (unsigned i = 0; i < FORK_COUNT; i++) {
		if (do_exit) {
			break;
		}

		fork_loop();
	}
	tracepoint(fork_test, process_terminated, getpid());

	return 0;
}
