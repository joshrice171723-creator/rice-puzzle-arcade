extends SceneTree

const Profile = preload("res://profile.gd")
const Run = preload("res://run.gd")
const PATH := "user://nightfall_preparation_test.json"
var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func cleanup() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))

func _initialize() -> void:
	call_deferred("journey")

func journey() -> void:
	cleanup()
	var p = Profile.new(PATH)
	p.load_save()
	check(not p.practice_unlocked(1), "Unseen bosses are initially locked")
	var attempt: Dictionary = p.start_attempt(1)
	var r = Run.new(attempt.seed)
	r.configure(1, p.stats())
	r.elapsed = r.duration - 0.01
	r.tick(0.02, Vector2.ZERO)
	check(p.checkpoint(r.snapshot()) and p.practice_unlocked(1), "Encountering a campaign boss unlocks practice at the checkpoint")
	var loaded = Profile.new(PATH)
	check(loaded.load_save() and loaded.practice_unlocked(1) and not loaded.practice_unlocked(2), "Boss discovery persists without unlocking later encounters")
	r.phase = "defeat"
	p.finish_attempt(attempt.id, r.result())
	check(p.practice_unlocked(1) and not p.mission_unlocked(2), "Defeat preserves boss practice access without granting a campaign clear")
	var arena = load("res://main.tscn").instantiate()
	arena.profile = Profile.new(PATH)
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.begin_practice(2, "Balanced")
	check(arena.home.visible, "Controller rejects a locked practice encounter")
	arena.begin_practice(1, "Invalid")
	check(arena.home.visible, "Controller rejects an unknown training build")
	var previous: Dictionary = arena.profile.data.duplicate(true)
	arena.begin_practice(1, "Close range")
	check(not arena.home.visible and arena.run.practice and arena.run.mission == 1 and arena.run.boss_name == "Garage Mauler", "Selected boss starts immediately in practice")
	check(arena.run.spells.keys() == ["wisp", "ground", "gravity"] and arena.run.health == arena.profile.stats().hp, "Practice uses chosen automatic spells and real equipped stats")
	arena.run.enemies[0].hp = 0
	arena.run.tick(0.02, Vector2.ZERO)
	arena.last_screen = ""
	arena.update_modal()
	check(arena.run.phase == "victory" and arena.profile.data == previous and arena.reward_receipt.is_empty(), "Practice victory does not grant loot, mastery, XP or campaign progress")
	arena.replay()
	check(arena.run.practice and arena.run.mission == 1 and arena.run.spells.keys() == ["wisp", "ground", "gravity"], "Practice replay keeps selected encounter and spell build")
	arena.show_haven()
	arena.start_campaign(1)
	arena.run.field.scrap = 37
	arena.show_haven()
	var campaign: Dictionary = arena.profile.data.active_attempt.duplicate(true)
	arena.begin_practice(1, "Projectiles")
	arena.run.phase = "defeat"
	arena.finish_to_haven()
	check(arena.profile.data.active_attempt == campaign, "Practice cannot overwrite an existing saved campaign")
	arena.resume_campaign()
	check(not arena.run.practice and arena.run.field.scrap == 37 and arena.run.paused, "Original expedition resumes after practice without lost resources")
	arena.queue_free()
	await process_frame
	# Older completed profiles infer encountered bosses once during migration.
	var legacy: Dictionary = p.data.duplicate(true)
	legacy.erase("seen_bosses")
	legacy.missions = {"1": ["clear"], "2": ["clear", "combat"]}
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	check(loaded.load_save() and loaded.practice_unlocked(1) and loaded.practice_unlocked(2) and not loaded.practice_unlocked(3), "Pre-discovery saves retain practice for previously cleared bosses")
	cleanup()
	print("Nightfall preparation: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
