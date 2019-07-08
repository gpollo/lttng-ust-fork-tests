#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>

#define TRACEPOINT_DEFINE
#include "tp_provider.h"

#define LAST_PID_FILE "/proc/sys/kernel/ns_last_pid"
#define DESIRED_PID 15000
#define PID_BUFFER_SIZE 10
#define FORK_COUNT 2

static char buffer[PID_BUFFER_SIZE];

static
int do_fork()
{
	int ret = 0;
	int fd, size, written;
	pid_t pid;

	fd = open(LAST_PID_FILE, O_RDWR);
	if (fd < 0) {
		perror("open");
		ret = 1;
		goto exit;
	}

	if (flock(fd, LOCK_EX) < 0) {
		perror("flock");
		ret = 1;
		goto flock_failed;
	}

	size = snprintf(buffer, PID_BUFFER_SIZE, "%d", DESIRED_PID-1);
	if (size < 0) {
		perror("snprintf");
		ret = 1;
		goto snprintf_failed;
	}
	if (size == 0) {
		fprintf(stderr, "snprintf: invalid size returned (%d)\n", size);
		ret = 1;
		goto snprintf_failed;
	}

	written = write(fd, buffer, size);
	if (written < 0) {
		perror("write");
		ret = 1;
	} else if (written != size) {
		fprintf(stderr, "write: expected %d bytes to be written, got %d\n", size, written);
		ret = 1;
	}

snprintf_failed:
	if (flock(fd, LOCK_UN) < 0) {
		perror("flock");
		ret = 1;
	}

flock_failed:
	if (close(fd) < 0) {
		perror("close");
		ret = 1;
		goto exit;
	}

	if (ret) {
		goto exit;
	}

	pid = fork();
	if (pid < 0) {
		perror("fork");
		ret = 1;
		goto exit;
	}

	if (pid) {
		tracepoint(fork_test, child_spawned, getpid(), pid);
		if (waitpid(pid, NULL, 0) < 0) {
			perror("waitpid");
			ret = 1;
		}
		tracepoint(fork_test, child_terminated, getpid(), pid);
	} else {
		printf("child spawned with PID=%d\n", getpid());
		tracepoint(fork_test, process_spawned, getpid());
		ret = 1;
	}

exit:
	return ret;
}

int main()
{
	tracepoint(fork_test, process_spawned, getpid());

	for (int i = 0; i < FORK_COUNT; i++) {
		if (do_fork()) {
			break;
		}
	}

	tracepoint(fork_test, process_terminated, getpid());

	return 0;
}
