#!/bin/bash

PROCESS_SPAWN_TP=fork_test:process_spawned
PROCESS_TERMI_TP=fork_test:process_terminated
CHILD_SPAWN_TP=fork_test:child_spawned
CHILD_TERMI_TP=fork_test:child_terminated

ERROR_CODE=0

if [[ ! -v SLEEP_COUNT ]]; then
	SLEEP_COUT=1
fi

assert_eq() {
	if [[ ! $2 -eq $3 ]]; then
		echo -e "$1 should be equal: expected=$2, got=$3"
		ERROR_CODE=1
	fi
}

start_sessiond() {
	lttng-sessiond -vvv --verbose-consumer > sessiond.log 2> sessiond.log &
	sleep 1

	SESSIOND_PID=$!
}

stop_sessiond() {
	kill -SIGINT "$SESSIOND_PID"
	wait "$SESSIOND_PID"
}

start_tracing_session() {
	lttng create test
	lttng enable-channel --userspace --overwrite channel --buffers-pid
	lttng enable-event -u "$PROCESS_SPAWN_TP" -c channel
	lttng enable-event -u "$PROCESS_TERMI_TP" -c channel
	lttng enable-event -u "$CHILD_SPAWN_TP" -c channel
	lttng enable-event -u "$CHILD_TERMI_TP" -c channel
	lttng start
}

stop_tracing_session() {
	#sleep 1
	lttng stop

	TRACE_DIRECTORY=$(lttng list test | grep -i "trace output" | sed "s/.* \(\/.*\)/\1/")

	babeltrace "$TRACE_DIRECTORY" > /dev/null 2> /dev/null
	if [[ $? -eq 0 ]]; then
		P_SPAWN=$(lttng view | grep "$PROCESS_SPAWN_TP"    | wc -l)
		P_TERMI=$(lttng view | grep "$PROCESS_TERMI_TP" | wc -l)
		echo -e "\tProcess spawned    = $P_SPAWN";
		echo -e "\tProcess terminated = $P_TERMI";

		C_SPAWN=$(lttng view | grep "$CHILD_SPAWN_TP"    | wc -l)
		C_TERMI=$(lttng view | grep "$CHILD_TERMI_TP" | wc -l)
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

start_fork() {
	if [[ -n $USE_VALGRIND ]]; then
		VALGRIND_OPTS="--log-file=run1.valgrind.log --leak-check=full --show-leak-kinds=all"
		echo | LD_PRELOAD=liblttng-ust-fork.so valgrind $VALGRIND_OPTS ./fork-preload $@ &
	else
		echo | LD_PRELOAD=liblttng-ust-fork.so ./fork-preload $@ &
	fi

	FORK_PID=$!
}

wait_fork() {
	seq $SLEEP_COUNT | while read N; do
		sleep 0.5
		printf "."
	done
	echo
}

stop_fork() {
	kill -SIGINT "$FORK_PID"
	wait "$FORK_PID"
}

make

start_sessiond
start_tracing_session

start_fork $@ > run1.log 2> run1.log
wait_fork
stop_fork

stop_tracing_session
stop_sessiond

exit $ERROR_CODE
