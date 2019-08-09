override CFLAGS+=-I../common/ -lpthread -ldl

EXECUTABLES=                     \
	$(shell basename ${PWD}) \
	$(shell basename ${PWD})-no-lttng

all: clean ${EXECUTABLES}

$(shell basename ${PWD}): main.c ../common/tp.c
	gcc $? -o $@ -llttng-ust ${CFLAGS}

$(shell basename ${PWD})-no-lttng: main.c
	gcc $? -o $@ -DNO_LTTNG ${CFLAGS}

clean:
	rm -f ${EXECUTABLES}
