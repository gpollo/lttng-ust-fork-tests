#undef TRACEPOINT_PROVIDER
#define TRACEPOINT_PROVIDER fork_test

#undef TRACEPOINT_INCLUDE
#define TRACEPOINT_INCLUDE "./tp_provider.h"

#if !defined(_TP_PROVIDER_H) || defined(TRACEPOINT_HEADER_MULTI_READ)
#define _TP_PROVIDER_H

#include <lttng/tracepoint.h> 

TRACEPOINT_EVENT(
	fork_test,
	test,
	TP_ARGS(
		unsigned, pid,
		char *, text
	),
	TP_FIELDS(
		ctf_integer(int, pid, pid)
		ctf_array_text(char, text, text, 40)
	)
)

#endif /* _TP_PROVIDER_H */

#include <lttng/tracepoint-event.h>
