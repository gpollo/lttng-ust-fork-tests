#!/bin/bash

EXECUTABLE=$(basename "$PWD")

function run_bin() {
	export LTTNG_UST_REGISTER_TIMEOUT=-1
	export LD_PRELOAD=liblttng-ust-fork.so
	./$EXECUTABLE 2> run.log > run.log
	unset LD_PRELOAD
}

time run_bin
