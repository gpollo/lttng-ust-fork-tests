CFLAGS=-lpthread -ldl -I. -Wall -Wextra -pedantic -fno-builtin -g -O0

EXECUTABLES=                    \
	fork                    \
	fork-test-atfork        \
     	fork-atfork fork-preload

all: clean ${EXECUTABLES}

fork: fork.c
	gcc ${CFLAGS} $? -o $@ -DNO_LTTNG

fork-test-atfork: fork.c
	gcc ${CFLAGS} $? -o $@ -DNO_LTTNG -DTEST_PTHREAD_ATFORK

fork-atfork: fork.c tp.c
	gcc ${CFLAGS} $? -o $@ -llttng-ust

fork-preload: fork.c tp.c
	gcc ${CFLAGS} $? -o $@ -llttng-ust -llttng-ust-fork

clean:
	rm -f ${EXECUTABLES}
	rm -f *.log
