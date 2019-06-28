#undef TRACEPOINT_PROVIDER
#define TRACEPOINT_PROVIDER fork_test

#undef TRACEPOINT_INCLUDE
#define TRACEPOINT_INCLUDE "./tp_provider.h"

#if !defined(_TP_PROVIDER_H) || defined(TRACEPOINT_HEADER_MULTI_READ)
#define _TP_PROVIDER_H

#include <lttng/tracepoint.h> 

TRACEPOINT_EVENT(
	fork_test,
	process_spawned,
	TP_ARGS(unsigned, pid),
	TP_FIELDS(ctf_integer(int, pid, pid))
)

TRACEPOINT_EVENT(
	fork_test,
	process_terminated,
	TP_ARGS(unsigned, pid),
	TP_FIELDS(ctf_integer(int, pid, pid))
)

TRACEPOINT_EVENT(
	fork_test,
	child_spawned,
	TP_ARGS(
		unsigned, pid,
		unsigned, child
	),
	TP_FIELDS(
		ctf_integer(int, pid, pid)
		ctf_integer(int, child, child)
	)
)

TRACEPOINT_EVENT(
	fork_test,
	child_terminated,
	TP_ARGS(
		unsigned, pid,
		unsigned, child
	),
	TP_FIELDS(
		ctf_integer(int, pid, pid)
		ctf_integer(int, child, child)
	)
)

#endif /* _TP_PROVIDER_H */

#include <lttng/tracepoint-event.h>
