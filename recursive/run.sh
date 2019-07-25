#!/bin/bash

EXECUTABLE=$(basename "$PWD")

function run_bin() {
	export LTTNG_UST_DEBUG=1
	export LTTNG_UST_REGISTER_TIMEOUT=-1
	export LTTNG_UST_ALLOW_BLOCKING=1
	export LD_PRELOAD=liblttng-ust-fork.so

	./$EXECUTABLE 2> run.log > run.log

	unset LTTNG_UST_DEBUG
	unset LTTNG_UST_REGISTER_TIMEOUT
	unset LTTNG_UST_ALLOW_BLOCKING
	unset LD_PRELOAD
}

time run_bin


