CFLAGS=-I. -Wall -Wextra -pedantic -fno-builtin -g -O0

EXECUTABLES=simple-fork

all: clean ${EXECUTABLES}

simple-fork: fork.c tp.c
	gcc ${CFLAGS} $? -o $@ -ldl -llttng-ust

clean:
	rm -f ${EXECUTABLES}
	rm -f *.log
