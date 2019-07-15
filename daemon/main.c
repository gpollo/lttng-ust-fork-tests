#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define TRACEPOINT_DEFINE
#include "tp_provider.h"

static void exit_handler(void)
{
	tracepoint(fork_test, process_terminated, getpid());
}

int main()
{
	if (atexit(exit_handler)) {
		fprintf(stderr, "atexit: failed to add an handler\n");
		return 1;
	}

	tracepoint(fork_test, process_spawned, getpid());

	if (daemon(0, 1)) {
		perror("daemon");
		return 1;
	}

	return 0;
}
