#!/bin/bash

export LTTNG_UST_REGISTER_TIMEOUT=-1

PROCESS_SPAWN_TP=fork_test:process_spawned
PROCESS_TERMI_TP=fork_test:process_terminated
CHILD_SPAWN_TP=fork_test:child_spawned
CHILD_TERMI_TP=fork_test:child_terminated



assert_eq() {
	if [[ ! $2 -eq $3 ]]; then
		echo -e "$1 should be equal: expected=$2, got=$3"
		ERROR_CODE=1
	fi
}

start_sessiond() {
	LTTNG_SESSIOND_CMD="lttng-sessiond -vvv --verbose-consumer --daemonize"
	$LTTNG_SESSIOND_CMD > sessiond.log 2> sessiond.log
	sleep 1

	SESSIOND_PID=$(ps aux | grep -i "$LTTNG_SESSIOND_CMD" | head -n1 | awk '{print $2}')
	echo "lttng-sessiond PID=$SESSIOND_PID"
}

stop_sessiond() {
	kill -SIGINT "$SESSIOND_PID"
	tail --pid="$SESSIOND_PID" -f /dev/null
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
	lttng stop

	TRACE_DIRECTORY=$(lttng list test | grep -i "trace output" | sed "s/.* \(\/.*\)/\1/")
	echo
	./list.sh "$TRACE_DIRECTORY"
}

run_fork() {
#LTTNG_UST_REGISTER_TIMEOUT=-1
	LTTNG_UST_DEBUG=1 LD_PRELOAD=liblttng-ust-fork.so ./simple-fork &
	wait $!
}

make

cleanup() {
	echo
}
trap cleanup INT
trap cleanup EXIT

start_sessiond
start_tracing_session

while printf .; do
	run_fork $@ 2> run.log > run.log
done

stop_tracing_session
stop_sessiond
