#!/bin/bash

assert_eq() {
	if [[ ! $2 -eq $3 ]]; then
		echo -e "$1 should be equal: expected=$2, got=$3"
	fi
}

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

	TRACE_DIRECTORY=$(lttng list test | grep -i "trace output" | sed "s/.* \(\/.*\)/\1/")

	babeltrace "$TRACE_DIRECTORY" > /dev/null 2> /dev/null
	if [[ $? -eq 0 ]]; then
		P_SPAWN=$(lttng view | grep "process spawned"    | wc -l)
		P_TERMI=$(lttng view | grep "process terminated" | wc -l)
		echo -e "\tProcess spawned    = $P_SPAWN";
		echo -e "\tProcess terminated = $P_TERMI";

		C_SPAWN=$(lttng view | grep "child spawned"    | wc -l)
		C_TERMI=$(lttng view | grep "child terminated" | wc -l)
		echo -e "\tChild spawned    = $C_SPAWN";
		echo -e "\tChild terminated = $C_TERMI";
	else
		echo -e "\tMissing events in traces"
	fi

	TRACE_COUNT=$(find "$TRACE_DIRECTORY" -maxdepth 3 -mindepth 3 | wc -l)
	echo -e "\tTrace directory = $TRACE_DIRECTORY"
	echo -e "\tTrace count = $TRACE_COUNT"

	assert_eq "\t\tProcess spawned/terminated" $P_SPAWN $P_TERMI
	assert_eq "\t\tChild spawned/terminated" $C_SPAWN $C_TERMI
	assert_eq "\t\tTrace count and process spawned" $TRACE_COUNT $P_SPAWN
}

run_fork() {
	if [[ -n $USE_VALGRIND ]]; then
		VALGRIND_OPTS="--log-file=run1.valgrind.log --leak-check=full --show-leak-kinds=all"
		echo | LD_PRELOAD=liblttng-ust-fork.so valgrind $VALGRIND_OPTS ./fork-preload $@
	else
		echo | LD_PRELOAD=liblttng-ust-fork.so ./fork-preload $@
	fi
}

make

start_sessiond
start_tracing_session

run_fork $@ > run1.log 2> run1.log

stop_tracing_session
stop_sessiond

