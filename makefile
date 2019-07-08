CFLAGS=-I. -Wall -Wextra -pedantic -fno-builtin -g -O0

EXECUTABLES=simple same-pid

all:
	for executable in $(EXECUTABLES); do $(MAKE) -C $$executable; done

clean:
	for executable in $(EXECUTABLES); do $(MAKE) clean -C $$executable; done

.PHONY: all $(EXECUTABLES) clean
