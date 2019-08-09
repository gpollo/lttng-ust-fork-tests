CFLAGS=-Wall -Wextra -pedantic -fno-builtin -g -O0 --std=c11

EXECUTABLES=simple same-pid recursive daemon

all:
	for executable in $(EXECUTABLES); do \
		cd $$executable; $(MAKE) CFLAGS=$(FLAGS); cd ..; \
	done

clean:
	for executable in $(EXECUTABLES); do \
		cd $$executable; $(MAKE) clean; cd ..; \
	done
	rm -v *.log

.PHONY: all $(EXECUTABLES) clean
