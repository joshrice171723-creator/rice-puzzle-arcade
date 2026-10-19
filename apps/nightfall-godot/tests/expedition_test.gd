extends SceneTree
## Controller-level journey with an isolated save and simulated SDK callbacks.

const Profile = preload("res://profile.gd")
const PATH := "user://nightfall_expedition_test.json"
var checks := 0
var failures := 0

class FakeAds:
	extends RefCounted
	var token := ""
	func showRewarded(value: String) -> void:
		token = value
	func cancelRewarded(_value: String) -> void:
		pass

func _initialize() -> void:
	call_deferred("journey")

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func cleanup() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))

func journey() -> void:
	cleanup()
	var arena = load("res://main.tscn").instantiate()
	arena.profile = Profile.new(PATH)
	root.add_child(arena)
	arena.set_physics_process(false)
	check(arena.home.visible and arena.run.paused, "Fresh launch opens Haven without starting combat")
	arena.start_campaign(1)
	check(not arena.home.visible and arena.attempt_id == 1 and arena.run.mission == 1 and arena.run.health == 210, "Venture starts a configured expedition and hides Haven")
	check(not arena.profile.saved_run().is_empty(), "Starting expedition immediately records a recoverable checkpoint")
	arena.run.field.add_loot("parts", "Workshop Parts", 4)
	arena.run.field.set_secure(0, true)
	arena.run.field.scrap = 80
	arena.run.field.active_site = 0
	arena.run.phase = "shrine"
	arena.run.buy_trait("vitality")
	arena.show_haven()
	check(arena.home.visible and not arena.profile.can_change_loadout(), "Returning to Haven saves and locks active-run equipment")
	arena.resume_campaign()
	check(arena.run.paused and arena.run.phase == "shrine" and arena.run.field.traits.vitality == 1 and arena.run.field.scrap == 50, "Resume restores the shrine transaction without resetting prices or funds")
	arena.run.paused = false
	arena.run.leave_shrine()
	arena.run.field.credits = 21
	arena.run.health = 0
	arena.run.phase = "defeat"
	arena.last_screen = ""
	arena.update_modal()
	check(arena.attempt_id == 1 and arena.profile.data.credits == 0, "Defeat waits for rescue or finish decision before banking")
	arena.ad_bridge = FakeAds.new()
	arena.request_rescue()
	var token: String = arena.ad_bridge.token
	check(not token.is_empty(), "Rescue asks native bridge using a specific request token")
	arena.failed_rescue(token, "Simulated no fill")
	check(arena.run.phase == "defeat" and not arena.run.rescued and arena.reward_flow.pending.is_empty(), "No-fill returns to defeat without consuming rescue")
	arena.request_rescue()
	token = arena.ad_bridge.token
	arena.earned_rescue(token)
	arena.finished_rescue(token, true)
	check(arena.run.rescued and arena.run.paused and arena.run.phase == "waves", "Earned callback changes the actual run into a paused rescued state")
	var restored = Profile.new(PATH)
	check(restored.load_save() and restored.saved_run().rescued, "Earned rescue is durable before video closure")
	arena.run.paused = false
	arena.run.phase = "victory"
	arena.run.field.caches_opened = 3
	arena.run.damage_taken = 2
	arena.last_screen = ""
	arena.update_modal()
	check(arena.attempt_id == 0 and arena.reward_receipt.victory and arena.profile.mission_unlocked(2), "Boss result banks reward and unlocks next mission")
	check("combat" not in arena.profile.data.missions["1"] and "scavenger" in arena.profile.data.missions["1"], "Rescue excludes combat medal but preserves earned scavenging medal")
	var balance: int = arena.profile.data.credits
	arena.last_screen = ""
	arena.update_modal()
	check(arena.profile.data.credits == balance, "Rebuilding result UI cannot double bank rewards")
	arena.finish_to_haven()
	check(arena.home.visible and arena.profile.can_change_loadout(), "Completed expedition returns to unlocked equipment management")
	check(arena.profile.upgrade_item(0) and arena.profile.item_by_id(0).level == 2, "Earned rewards can buy a real persistent equipment upgrade")
	arena.start_campaign(2)
	check(arena.run.boss_name == "Fence Runner" and arena.run.damage > 24, "Next mission uses its boss and upgraded weapon stats")
	arena.run.field.add_loot("parts", "Parts", 5)
	arena.run.field.add_loot("gear", "Outrider Boots", 1, "rare", "boots")
	arena.run.field.set_secure(0, true)
	# A failed Base transition must not replace this live run with an older checkpoint.
	arena.run.spawn_enemy()
	var target: Dictionary = arena.run.enemies.back()
	arena.run.damage_enemy(target, 12, arena.run.player)
	var pending_xp: Dictionary = arena.run.combat_xp.duplicate()
	var previous_snapshot: Dictionary = arena.profile.saved_run()
	arena.profile.path = "user://missing-expedition-checkpoint-dir/save.json"
	var live_run: RefCounted = arena.run
	arena.show_haven()
	check(not arena.home.visible and arena.run == live_run and arena.run.paused and arena.run.combat_xp == pending_xp, "Failed return to Base keeps live earned combat XP paused in memory")
	check(arena.profile.saved_run() == previous_snapshot and not arena.profile.error.is_empty(), "Failed checkpoint preserves old disk snapshot and surfaces save error")
	arena.profile.path = PATH
	arena.show_haven()
	check(arena.home.visible and arena.profile.error.is_empty(), "Retry saves before opening Base")
	arena.resume_campaign()
	check(arena.run.combat_xp == pending_xp, "Resume after successful retry restores all pending combat XP")
	arena.show_haven()
	arena.abandon_campaign()
	check(arena.profile.data.active_attempt.is_empty() and arena.profile.data.last_result.parts == 5 and arena.profile.data.last_result.lost == 1, "Abandon banks protected loot and loses unsecured gear exactly once")
	check(arena.profile.data.last_result.combat_xp == pending_xp, "Ending saved expedition banks all recovered combat XP")
	arena.queue_free()
	await process_frame
	cleanup()
	print("Nightfall expedition integration: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
