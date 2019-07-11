#!/bin/bash

EXECUTABLE=$(basename "$PWD")

export LTTNG_UST_REGISTER_TIMEOUT=-1
export LD_PRELOAD=liblttng-ust-fork.so
./$EXECUTABLE &
./$EXECUTABLE &
./$EXECUTABLE &
./$EXECUTABLE &
./$EXECUTABLE &
unset LTTNG_UST_REGISTER_TIMEOUT
unset LD_PRELOAD
wait $(jobs -p)
