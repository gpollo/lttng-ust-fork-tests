#include <stdio.h>
#include <unistd.h>
#include <time.h>
#include <sys/types.h>
#include <sys/wait.h>

#define TRACEPOINT_DEFINE
#include "tp_provider.h"

#define FORK_COUNT 1000

#define VA_ARGS(...) , ##__VA_ARGS__
#define log(fmt, ...) 							\
	do { 								\
		time_t ts; 						\
		ts = time(NULL); 					\
		char* date = asctime(localtime(&ts)); 			\
		date[strlen(date) - 1] = '\0';				\
		printf("[%s] " fmt "\n", date VA_ARGS(__VA_ARGS__));	\
	} while (0);

int main()
{
	tracepoint(fork_test, process_spawned, getpid());

	for(int i = 0; i < FORK_COUNT; i++) {
		pid_t pid = fork();
		if (pid < 0) {
			perror("fork");
			break;
		}

		if (pid) {
			tracepoint(fork_test, child_spawned, getpid(), pid);
			log("waiting for child...");
			pid_t child = wait(NULL);
			if (child < 0) {
				perror("wait");
			}
			log("done waiting for child %u", child);
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
