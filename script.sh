#!/bin/bash

set -o xtrace

start_sessiond() {
	lttng-sessiond -vvv --verbose-consumer > sessiond.log 2> sessiond.log &
	sleep 1
}

stop_sessiond() {
	kill -SIGINT $(jobs -p)
	wait $(jobs -p)
}

start_tracing_session() {
	lttng create test
	lttng enable-channel --userspace --overwrite channel --buffers-pid
	lttng enable-event -u fork_test:test -c channel
	lttng start
}

stop_tracing_session() {
	lttng stop
	lttng view
}

run_fork() {
	echo | LD_PRELOAD=liblttng-ust-fork.so ./fork-preload
}

make

start_sessiond
start_tracing_session

run_fork > run1.log 2> run1.log

stop_tracing_session
stop_sessiond

