CFLAGS=-lpthread -ldl -I. -Wall -Wextra -pedantic -fno-builtin -g -O0

EXECUTABLES=fork fork-preload

all: clean ${EXECUTABLES}

fork: fork.c
	gcc ${CFLAGS} $? -o $@ -DNO_LTTNG

fork-preload: fork.c tp.c
	gcc ${CFLAGS} $? -o $@ -llttng-ust -llttng-ust-fork

clean:
	rm -f ${EXECUTABLES}
	rm -f *.log
