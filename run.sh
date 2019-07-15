#!/bin/bash

SESSIOND_CMD="lttng-sessiond -vvv --verbose-consumer --background"

LTTNG_SESSION="fork"
LTTNG_CHANNEL="test"

TP_PROCESS_SPAWN="fork_test:process_spawned"
TP_PROCESS_TERMI="fork_test:process_terminated"
TP_CHILD_SPAWN="fork_test:child_spawned"
TP_CHILD_TERMI="fork_test:child_terminated"

START_DIR=$(pwd)

reset_dir() {
	cd "$START_DIR" || return
}

setup_cleanup_handler() {
	cleanup() {
		echo "SIGINT trapped, exiting..."
	}

	trap cleanup INT
}

start_sessiond() {
	$SESSIOND_CMD > sessiond.log 2> sessiond.log
	SESSIOND_PID=$(pgrep -f "$SESSIOND_CMD" | tr '\n' ' ' | awk '{print $1}')
}

stop_sessiond() {
	kill -SIGINT "$SESSIOND_PID"
	tail --pid="$SESSIOND_PID" -f /dev/null
}

start_tracing_session() {
	TRACE=$(mktemp -d)

	lttng create $LTTNG_SESSION --output "$TRACE"
	lttng enable-channel --userspace --overwrite $LTTNG_CHANNEL --buffers-pid
	lttng enable-event -c $LTTNG_CHANNEL -u $TP_PROCESS_SPAWN
	lttng enable-event -c $LTTNG_CHANNEL -u $TP_PROCESS_TERMI
	lttng enable-event -c $LTTNG_CHANNEL -u $TP_CHILD_SPAWN
	lttng enable-event -c $LTTNG_CHANNEL -u $TP_CHILD_TERMI
	lttng start $LTTNG_SESSION
}

stop_tracing_session() {
	lttng stop $LTTNG_SESSION
	./list.sh "$TRACE"
}

run_fork() {
	local executable=$1

	if [[ ! -d "$executable" ]]; then
		echo "Executable '$executable' directory not found"
		return
	fi

	cd "$executable" || return
	echo -----------------------
	./run.sh
	echo -----------------------
	reset_dir
}

make

start_sessiond
start_tracing_session

setup_cleanup_handler
run_fork "$@"

stop_tracing_session
stop_sessiond
