extends RefCounted
## A pending shop video has one owner and can grant one persisted supply key.
var pending := ""
var earned := false
var granted := false
var closed := false
var message := ""

func begin(profile: RefCounted) -> String:
	if not pending.is_empty() or profile.blocked or profile.shop_videos_left() <= 0:
		return ""
	pending = "shop-%d-%d" % [Time.get_unix_time_from_system(), Time.get_ticks_usec()]
	earned = false
	granted = false
	closed = false
	message = "Loading video… Complete it to earn one supply key."
	return pending

func reward(token: String, profile: RefCounted) -> bool:
	if pending.is_empty() or token != pending:
		return false
	earned = true
	granted = profile.grant_shop_video(token)
	message = "Supply key saved. Open a chest in the Shop." if granted else "Reward earned, but saving failed. Free space and retry saving."
	if closed and granted:
		pending = ""
	return granted

func finish(token: String) -> bool:
	if pending.is_empty() or token != pending:
		return false
	closed = true
	if not earned or granted:
		message = "Supply key saved." if granted else "Video closed without a reward. No daily claim was used."
		pending = ""
	return true

func fail(token: String, reason: String) -> bool:
	if pending.is_empty() or token != pending:
		return false
	closed = true
	if not earned:
		pending = ""
		message = reason
	elif granted:
		pending = ""
	return true
