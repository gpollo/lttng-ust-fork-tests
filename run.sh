#!/bin/bash

SESSIOND_CMD="lttng-sessiond -vvv --verbose-consumer --background"

LTTNG_SESSION=fork
LTTNG_CHANNEL=test

TP_PROCESS_SPAWN=fork_test:process_spawned
TP_PROCESS_TERMI=fork_test:process_terminated
TP_CHILD_SPAWN=fork_test:child_spawned
TP_CHILD_TERMI=fork_test:child_terminated

setup_cleanup_handler() {
    cleanup() {
        echo "Exiting..."
        stop_tracing_session
        stop_sessiond
        exit
    }

    trap cleanup INT
}

start_sessiond() {
	$SESSIOND_CMD > sessiond.log 2> sessiond.log
	SESSIOND_PID=$(ps aux | grep -i "$SESSIOND_CMD" | head -n1 | awk '{print $2}')
}

stop_sessiond() {
	kill -SIGINT "$SESSIOND_PID"
	tail --pid="$SESSIOND_PID" -f /dev/null
}

start_tracing_session() {
	TRACE=$(mktemp -d)

	lttng create $LTTNG_SESSION --output $TRACE
	lttng enable-channel --userspace --overwrite $LTTNG_CHANNEL --buffers-pid
	lttng enable-event -c $LTTNG_CHANNEL -u $TP_PROCESS_SPAWN
	lttng enable-event -c $LTTNG_CHANNEL -u $TP_PROCESS_TERMI
	lttng enable-event -c $LTTNG_CHANNEL -u $TP_CHILD_SPAWN
	lttng enable-event -c $LTTNG_CHANNEL -u $TP_CHILD_TERMI
	lttng start $LTTNG_SESSION
}

stop_tracing_session() {
	lttng stop $LTTNG_SESSION
	./list.sh $TRACE
}

run_fork() {
    local executable=$1
    local last_dir=$(pwd)

    if [[ ! -d $executable ]]; then
        echo "Executable '$executable' directory not found"
        return
    fi

    cd $executable
    make

    if [[ ! -f $executable ]]; then
        echo "Executable '$executable' file not found"
        cd "$last_dir"
        return
    fi

	export LTTNG_UST_REGISTER_TIMEOUT=-1
	export LD_PRELOAD=liblttng-ust-fork.so
	echo
    ./$executable
	echo
	unset LTTNG_UST_REGISTER_TIMEOUT
	unset LD_PRELOAD

    cd "$last_dir"
}

start_sessiond
start_tracing_session

setup_cleanup_handler
run_fork $@

stop_tracing_session
stop_sessiond
