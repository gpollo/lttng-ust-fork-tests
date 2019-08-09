override CFLAGS+=-I../common/ -Wall -Wextra -pedantic -fno-builtin -g -O0

EXECUTABLE=$(shell basename ${PWD})

all: clean ${EXECUTABLE}

${EXECUTABLE}: main.c ../common/tp.c
	gcc ${CFLAGS} $? -o $@ -ldl -llttng-ust

clean:
	rm -f ${EXECUTABLE}
