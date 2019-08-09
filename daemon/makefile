override CFLAGS+=-I../common/

EXECUTABLE=$(shell basename ${PWD})

all: clean ${EXECUTABLE}

${EXECUTABLE}: main.c ../common/tp.c
	gcc $? -o $@ -ldl -llttng-ust ${CFLAGS}

clean:
	rm -f ${EXECUTABLE}
