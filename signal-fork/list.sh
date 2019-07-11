#!/bin/bash

export BABELTRACE_TERM_COLOR=ALWAYS

assert_eq() {
	if [[ ! $2 -eq $3 ]]; then
		echo -e "$1 should be equal: expected=$2, got=$3"
	fi
}


find $1 -maxdepth 3 -mindepth 3 | sort | while read DIR; do 
	echo "$DIR"

	babeltrace "$DIR" > /dev/null 2> /dev/null
	if [[ $? -eq 0 ]]; then
		babeltrace "$DIR";

		P_SPAWN=$(babeltrace "$DIR" | grep "process spawned"    | wc -l)
		P_TERMI=$(babeltrace "$DIR" | grep "process terminated" | wc -l)

		C_SPAWN=$(babeltrace "$DIR" | grep "child spawned"    | wc -l)
		C_TERMI=$(babeltrace "$DIR" | grep "child terminated" | wc -l)

		assert_eq "Process spawned/terminated" $P_SPAWN $P_TERMI
		assert_eq "Child spawned/terminated" $C_SPAWN $C_TERMI
	else
		echo -e "Missing events in traces"
	fi

	echo;
done

