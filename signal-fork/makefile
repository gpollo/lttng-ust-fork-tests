override CFLAGS+=-lpthread -ldl

EXECUTABLES=fork fork-preload

all: clean ${EXECUTABLES}

fork: fork.c
	gcc $? -o $@ -DNO_LTTNG ${CFLAGS}

fork-preload: fork.c tp.c
	gcc $? -o $@ -llttng-ust -llttng-ust-fork ${CFLAGS}

clean:
	rm -f ${EXECUTABLES}
	rm -f *.log
