CFLAGS=-I. -Wall -Wextra -pedantic -fno-builtin -g -O0

EXECUTABLES=simple same-pid

all:
	for executable in $(EXECUTABLES); do cd $$executable; $(MAKE); cd ..; done

clean:
	for executable in $(EXECUTABLES); do cd $$executable; $(MAKE) clean; cd ..; done

.PHONY: all $(EXECUTABLES) clean
