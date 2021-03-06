#!/bin/bash

TP_PROC_SPAWN=fork_test:process_spawned
TP_PROC_TERMI=fork_test:process_terminated
TP_CHILD_SPAWN=fork_test:child_spawned
TP_CHILD_TERMI=fork_test:child_terminated

ERROR_COUNT_FILE=$(mktemp)

init_error_count() {
	echo 0 > "$ERROR_COUNT_FILE"
}

increment_error_count() {
	local result
	result=$(printf "%s+1\n" "$(cat "$ERROR_COUNT_FILE")" | bc)
	echo "$result" > "$ERROR_COUNT_FILE"
}

get_error_count() {
	cat "$ERROR_COUNT_FILE"
}

echo_error() {
	local msg=$1

	tput setaf 1
	echo -e "error: $msg"
	tput sgr0

	increment_error_count
}

assert_eq() {
	local msg=$1
	local expected=$2
	local got=$3

	if [[ ! "$expected" -eq "$got" ]]; then
		echo_error "$msg (expected=$expected, got=$got)"
	else 
		echo -e "ok: $msg"
	fi
}

check_trace() {
	local trace_dir=$1
	local temp_file=$2
	local count
	local p1
	local p2
	local c1
	local c2

	echo "$trace_dir"
	if ! babeltrace "$trace_dir" > /dev/null 2> /dev/null; then
		echo_error "babeltrace: couldn't read the trace"
		return
	fi

	babeltrace "$trace_dir"
	babeltrace "$trace_dir" > "$temp_file"

	count=$(wc -l < "$temp_file")
	p1=$(grep -c $TP_PROC_SPAWN < "$temp_file")
	p2=$(grep -c $TP_PROC_TERMI < "$temp_file")
	c1=$(grep -c $TP_CHILD_SPAWN < "$temp_file")
	c2=$(grep -c $TP_CHILD_TERMI < "$temp_file")

	assert_eq "process spawned/terminated should be equal" "$p1" "$p2"
	assert_eq "child spawned/terminated should be equal" "$c1" "$c2"
}

check_session_traces() {
	local session_dir=$1
	local temp_file

	temp_file=$(mktemp)
	find "$session_dir" -maxdepth 3 -mindepth 3 | sort | while read -r trace_dir; do
		check_trace "$trace_dir" "$temp_file"
		echo
	done
}

init_error_count
check_session_traces "$@"

tput setaf 3
echo -e "There have been $(get_error_count) error(s)."
tput sgr0
