#!/bin/bash

EXECUTABLE=$(basename "$PWD")
EXECUTABLE_PID=""
SLEEP_COUNT=5

start_application() {
	local depth=$1

	export LTTNG_UST_REGISTER_TIMEOUT=-1
	export LD_PRELOAD=liblttng-ust-fork.so
	./$EXECUTABLE "$depth" &
	unset LTTNG_UST_REGISTER_TIMEOUT
	unset LD_PRELOAD

	EXECUTABLE_PID=$!
}

wait_application() {
	seq $SLEEP_COUNT | while read N; do
		printf "\rSleeping %d/%d " "$N" "$SLEEP_COUNT"
		sleep 1
	done
	echo
}

stop_application() {
	kill -SIGINT "$EXECUTABLE_PID"
	wait "$EXECUTABLE_PID"
}

start_application
wait_application
stop_application

