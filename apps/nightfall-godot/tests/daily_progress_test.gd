extends SceneTree
const Profile = preload("res://profile.gd")
const Daily = preload("res://daily_progress.gd")
const DailyUI = preload("res://daily_ui.gd")
const Run = preload("res://run.gd")
const PATH := "user://nightfall_daily_progress_test.json"
var checks := 0
var failures := 0
var clock := [20000]
var capture_dir := ""

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func cleanup() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))

func fresh_profile() -> RefCounted:
	var p = Profile.new(PATH)
	p.utc_now = func() -> int: return clock[0] * 86400
	return p

func outcome(kills: int = 60, caches: int = 2, seconds: float = 61.0) -> Dictionary:
	return {"victory": false, "kills": kills, "caches": caches, "seconds": seconds, "progress_eligible": true}

func bank(p: RefCounted, result: Dictionary) -> int:
	var attempt: Dictionary = p.start_attempt(1)
	check(not attempt.is_empty(), "Start a real attempt for daily progress")
	check(not p.finish_attempt(attempt.id, result).is_empty(), "Bank daily progress with normal expedition result")
	return attempt.id

func settle() -> void:
	for frame in 6:
		await process_frame

func find_button(node: Node, prefix: String) -> Button:
	if node is Button and node.text.begins_with(prefix):
		return node
	for child in node.get_children():
		var found := find_button(child, prefix)
		if found != null:
			return found
	return null

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
	call_deferred("verify")

func verify() -> void:
	cleanup()
	var p = fresh_profile()
	var legacy: Dictionary = p.fresh()
	legacy.version = 3
	legacy.erase("daily")
	legacy.active_attempt = {"id": 1, "checkpoint": "do-not-change"}
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	check(p.load_save() and p.valid(p.data), "Version 3 gains validated daily state")
	check(p.data.active_attempt == legacy.active_attempt and p.data.inventory == legacy.inventory, "Daily migration preserves active expedition and gear")
	var baseline_stats: Dictionary = p.stats()
	check(p.claim_calendar() and p.stats() == baseline_stats, "Calendar works with saved expedition without altering its loadout")
	check(not p.claim_calendar() and p.data.credits == 75, "Calendar grant is once per UTC day")
	var reloaded = fresh_profile()
	check(reloaded.load_save() and not reloaded.claim_calendar(), "Restart cannot repeat a calendar claim")
	clock[0] -= 1
	check(not p.claim_calendar(), "Clock rollback cannot create a new claim")
	clock[0] += 8
	check(p.claim_calendar() and p.data.parts == 3 and p.data.daily.calendar_count == 2, "Missed days pause calendar rather than reset or skip rewards")
	for index in range(2, 7):
		clock[0] += 1
		check(p.claim_calendar(), "Claim calendar day " + str(index + 1))
	check(p.data.credits == 175 and p.data.parts == 8 and p.data.gems == 10 and p.data.cache_keys == 3, "Full seven-claim cycle grants exact documented rewards")
	clock[0] += 1
	var before: Dictionary = p.data.duplicate(true)
	p.path = "user://missing-daily-progress-folder/save.json"
	check(not p.claim_calendar() and p.data == before, "Failed calendar save rolls back reward and date")
	p.path = PATH
	check(p.claim_calendar() and p.data.credits == 250, "Next cycle restarts at first reward after successful retry")
	p = fresh_profile()
	check(p.save(), "Save new daily fixture")
	bank(p, outcome(100, 4, 59))
	check(Daily.completed(p.daily_state()) == 0, "Short abandoned attempt cannot farm objectives")
	bank(p, outcome(70, 2))
	check(p.data.daily.progress.kills == 70 and p.data.daily.progress.caches == 2, "A qualifying defeat retains kill and cache progress")
	var id := bank(p, outcome(40, 2))
	check(Daily.completed(p.daily_state()) == 3 and Daily.available_bonuses(p.daily_state()) == 1, "Three objectives can complete entirely through defeats")
	before = p.data.duplicate(true)
	check(p.finish_attempt(id, outcome()).is_empty() and p.data == before, "Repeated bank callback cannot duplicate daily progress")
	p.path = "user://missing-daily-progress-folder/save.json"
	check(not p.claim_daily_bonus() and p.data == before, "Daily claim write failure keeps earned reward available")
	p.path = PATH
	check(p.claim_daily_bonus() and p.data.credits == 75 and p.data.parts == 3 and p.data.cache_keys == 1, "Daily claim saves exact bonus once")
	check(not p.claim_daily_bonus(), "Repeated daily claim is rejected")
	var won := outcome()
	won.victory = true
	bank(p, won)
	check(Daily.completed(p.daily_state()) == 4 and not p.claim_daily_bonus(), "Fourth objective cannot issue a second daily bonus")
	clock[0] += 1
	bank(p, outcome())
	bank(p, outcome())
	clock[0] += 1
	var view: Dictionary = p.daily_state()
	check(Daily.completed(view) == 0 and Daily.available_bonuses(view) == 1, "Earned unclaimed bonus survives refresh while new progress starts empty")
	check(p.data.daily.day < view.day, "Reading a refreshed page does not mutate the save")
	bank(p, outcome())
	bank(p, outcome())
	check(Daily.available_bonuses(p.daily_state()) == 2, "Previously earned and current bonuses remain separately claimable")
	var old_keys: int = p.data.cache_keys
	check(p.claim_daily_bonus() and p.data.cache_keys == old_keys + 2, "Carry-forward claims grant two bundles exactly once")
	reloaded = fresh_profile()
	check(reloaded.load_save() and reloaded.valid(reloaded.data) and not reloaded.claim_daily_bonus(), "Claimed carried rewards survive restart without duplication")
	clock[0] += 1
	var attempt: Dictionary = p.start_attempt(1)
	before = p.data.duplicate(true)
	p.path = "user://missing-daily-progress-folder/save.json"
	check(p.finish_attempt(attempt.id, outcome()).is_empty() and p.data == before, "Failed expedition bank rolls back both old rewards and daily progress")
	p.path = PATH
	clock[0] += 1
	check(not p.finish_attempt(attempt.id, outcome()).is_empty() and p.data.daily.day == clock[0] and p.data.daily.progress.attempts == 1, "Cross-midnight attempt credits completion day exactly once on retry")
	var invalid: Dictionary = p.data.duplicate(true)
	invalid.daily.progress.kills = -1
	check(not p.valid(invalid), "Negative daily progress rejected on load")
	invalid = p.data.duplicate(true)
	invalid.daily.claimed = true
	check(not p.valid(invalid), "Claim flag without three complete tasks rejected")
	p.blocked = true
	check(not p.claim_calendar() and not p.claim_daily_bonus(), "Unreadable save cannot grant rewards")
	p.blocked = false
	var run = Run.new(123)
	run.practice = true
	check(not run.result().progress_eligible, "Training never contributes to daily objectives")
	run.practice = false
	run.benchmark_count = 10
	check(not run.result().progress_eligible, "Benchmark never contributes to daily objectives")
	var state: Dictionary = Daily.fresh()
	Daily.record(state, run.result())
	check(Daily.completed(state) == 0, "Excluded outcome cannot update counters")
	# Quick Upgrade spends one transaction, even when several levels are affordable.
	p = fresh_profile()
	p.data.credits = 260
	p.data.parts = 9
	# Funded bulk-purchase arithmetic assumes an eligible class at the equipment cap.
	p.data.class_combat.scavenger.xp.ranged = float(p.Training.threshold(9))
	p.sync_training_alias()
	check(p.quick_upgrade_cost(0) == {"levels": 3, "credits": 240, "parts": 9}, "Quick Upgrade previews max affordable steps")
	check(p.quick_upgrade_item(0) and p.item_by_id(0).level == 4 and p.data.credits == 20 and p.data.parts == 0, "Quick Upgrade charges exact total and preserves remaining currency")
	check(p.quick_upgrade_cost(0).is_empty() and not p.quick_upgrade_item(0), "Unaffordable quick upgrade has no effects")
	p.data.credits = 1000
	p.data.parts = 100
	p.data.facilities.workshop = 2
	check(p.quick_upgrade_cost(0) == {"levels": 1, "credits": 144, "parts": 5}, "Quick Upgrade respects current Workshop discount and level cap")
	before = p.data.duplicate(true)
	p.path = "user://missing-daily-progress-folder/save.json"
	check(not p.quick_upgrade_item(0) and p.data == before, "Failed multi-level upgrade rolls back entire purchase")
	p.path = PATH
	p.data.active_attempt = {"id": 20}
	check(not p.quick_upgrade_item(0), "Active expedition locks quick upgrading")
	p.data.active_attempt = {}
	check(p.quick_upgrade_item(0) and p.item_by_id(0).level == 5 and p.quick_upgrade_cost(0).is_empty(), "Quick Upgrade never exceeds playable level ceiling")
	check(p.quick_upgrade_cost(999).is_empty() and not p.quick_upgrade_item(999), "Missing item cannot quick upgrade")
	var arena = load("res://main.tscn").instantiate()
	arena.testing = true
	arena.profile = p
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.home.show()
	var home: Control = arena.home
	for viewport in [Vector2i(320, 568), Vector2i(430, 760)]:
		root.size = viewport
		for page in ["daily", "calendar"]:
			home.page = page
			home.rebuild()
			await settle()
			check(find_button(home, "Supplies") != null and find_button(home, "Objectives") != null, "Both daily destinations have navigation")
			check(home.body.get_global_rect().end.y <= home.navigation.position.y, page + " fits above fixed phone navigation")
			if page == "calendar":
				var claim: Button = find_button(home, "Claim ")
				check(claim != null, "Calendar action is visible")
				if claim != null:
					claim.pressed.emit()
					await settle()
					check(find_button(home, "Supplies claimed today") != null, "Actual calendar button updates persisted claim state")
			if not capture_dir.is_empty() and DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(capture_dir.path_join(page + "-" + str(viewport.x) + ".png"))
		clock[0] += 1
	arena.queue_free()
	await process_frame
	cleanup()
	print("Nightfall daily progression: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
