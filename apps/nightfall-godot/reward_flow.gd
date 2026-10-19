extends RefCounted
## A video earns a rescue only for the exact live expedition that requested it.

var pending := ""
var attempt := 0
var sequence := 0
var granted := false
var message := ""

func begin(attempt_id: int, run: RefCounted) -> String:
	if not pending.is_empty() or attempt_id <= 0 or run.phase != "defeat" or run.rescued:
		return ""
	sequence += 1
	attempt = attempt_id
	pending = "rescue-%d-%d-%d" % [attempt_id, Time.get_ticks_usec(), sequence]
	granted = false
	message = "Loading an optional Google test video. Completing it restores 50% health."
	return pending

func earned(token: String, attempt_id: int, run: RefCounted) -> bool:
	if token != pending or pending.is_empty() or attempt_id != attempt or granted:
		return false
	if not run.rescue():
		return false
	granted = true
	message = "Rescue earned. Close the video, then resume when ready."
	return true

func finish(token: String) -> bool:
	if token != pending or pending.is_empty():
		return false
	message = "Rescue earned." if granted else "Video closed without a reward. You can retry or finish the expedition."
	pending = ""
	return true

func fail(token: String, reason: String) -> bool:
	if token != pending or pending.is_empty():
		return false
	message = reason
	pending = ""
	return true
