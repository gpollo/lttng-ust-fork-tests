CFLAGS=-I. -Wall -Wextra -pedantic -fno-builtin -g -O0

EXECUTABLES=simple same-pid recursive daemon

all:
	for executable in $(EXECUTABLES); do cd $$executable; $(MAKE); cd ..; done

clean:
	for executable in $(EXECUTABLES); do cd $$executable; $(MAKE) clean; cd ..; done
	rm -v *.log

.PHONY: all $(EXECUTABLES) clean
