CFLAGS=-I../common/ -lpthread -ldl -Wall -Wextra -pedantic -fno-builtin -g -O0

EXECUTABLES=                     \
	$(shell basename ${PWD}) \
	$(shell basename ${PWD})-no-lttng

all: clean ${EXECUTABLES}

$(shell basename ${PWD}): main.c ../common/tp.c
	gcc ${CFLAGS} $? -o $@ -llttng-ust

$(shell basename ${PWD})-no-lttng: main.c
	gcc ${CFLAGS} $? -o $@ -DNO_LTTNG

clean:
	rm -f ${EXECUTABLES}
