extends SceneTree

const Run = preload("res://run.gd")
const Profile = preload("res://profile.gd")
const Salvage = preload("res://salvage.gd")
const Flow = preload("res://reward_flow.gd")
const Review = preload("res://combat_preview.gd")
const PATH := "user://nightfall_salvage_test.json"
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
	check(p.start_contract("weapon").is_empty(), "Contracts require the first campaign clear")
	p.data.missions["1"] = ["clear"]
	check(p.start_contract("invalid").is_empty(), "Unknown target slots are rejected")
	check(p.start_contract("weapon","invalid").is_empty(),"Unknown weapon families cannot start or consume an attempt")
	var attempt: Dictionary = p.start_contract("boots")
	check(attempt.mode == "salvage" and attempt.target_slot == "boots", "Contract records its own mode and chosen slot")
	check(p.start_contract("weapon").is_empty() and p.start_attempt(2).is_empty(), "Contract shares the single active expedition lock")
	var r = Run.new(attempt.seed)
	r.configure_contract(p.stats(), "boots")
	check(r.duration == 180 and r.mode == "salvage" and r.boss_id == -1, "Contract has a three-minute extraction window and no boss")
	r.player = Salvage.EXIT
	r.elapsed = 91
	r.field.caches_opened = 2
	Salvage.tick(r, 3)
	check(r.extract_progress == 0, "Beacon rejects fewer than three opened caches")
	r.field.caches_opened = 3
	r.elapsed = 89
	Salvage.tick(r, 3)
	check(r.extract_progress == 0, "Beacon does not become available before ninety seconds")
	r.elapsed = 90
	Salvage.tick(r, 1)
	check(r.extract_progress == 1 and r.phase == "waves", "Ready beacon requires a continuous three-second hold")
	r.player += Vector2(61, 0)
	Salvage.tick(r, 0.1)
	check(r.extract_progress == 0, "Leaving the beacon resets the hold")
	r.player = Salvage.EXIT
	r.paused = true
	Salvage.tick(r, 3)
	check(r.extract_progress == 0, "Pause cannot advance extraction")
	r.paused = false
	r.phase = "upgrade"
	Salvage.tick(r, 3)
	check(r.extract_progress == 0, "Choosing an upgrade cannot advance extraction")
	r.phase = "waves"
	Salvage.tick(r, 1.5)
	check(p.checkpoint(r.snapshot()), "Partially charged contract checkpoints")
	var loaded = Profile.new(PATH)
	check(loaded.load_save() and loaded.data.active_attempt.target_slot == "boots", "Reload preserves contract identity")
	var resumed = Run.new()
	check(resumed.restore(loaded.saved_run()) and resumed.mode == "salvage" and resumed.target_slot == "boots" and resumed.extract_progress == 1.5, "Checkpoint preserves extraction and targeted loot")
	resumed.paused = false
	Salvage.tick(resumed, 1.5)
	check(resumed.phase == "victory" and resumed.boss_id == -1, "Full hold completes the contract without inventing a boss")
	var receipt: Dictionary = loaded.finish_attempt(attempt.id, resumed.result())
	check(receipt.credits == 80 and receipt.parts == 2 and receipt.survivor_xp == 45 and receipt.mastery_xp == 25, "Contract banks its advertised completion reward")
	check(loaded.data.inventory.back().slot == "boots" and loaded.data.inventory.back().rarity in ["common", "uncommon"], "Contract produces equipment for the selected slot")
	check(receipt.new_medals.is_empty() and receipt.gems == 0 and loaded.data.missions == {"1": ["clear"]}, "Side mode cannot grant campaign medals, first-clear gems or mission progress")
	check(loaded.finish_attempt(attempt.id, resumed.result()).is_empty() and loaded.data.contract_clears == 1, "Duplicate result cannot count twice")
	p = loaded
	for number in range(2, 4):
		attempt = p.start_contract("weapon")
		receipt = p.finish_attempt(attempt.id, {"victory": true})
		check(receipt.keys == (1 if number == 3 else 0), "Supply key is earned on every third completed contract")
	check(p.data.cache_keys == 1 and p.data.contract_clears == 3, "Contract key progress persists")
	for family: String in Run.Weapons.TYPES:
		attempt = p.start_contract("weapon",family)
		r = Run.new(attempt.seed)
		r.configure_contract(p.stats(),attempt.target_slot,attempt.target_weapon)
		check(r.target_weapon==family and r.weapon_id=="pistol","Target reward does not grant the weapon before earning it")
		check(p.checkpoint(r.snapshot()),"Targeted weapon contract checkpoints")
		loaded = Profile.new(PATH)
		check(loaded.load_save() and loaded.data.active_attempt.target_weapon==family,"Chosen weapon survives restart")
		resumed = Run.new()
		check(resumed.restore(loaded.saved_run()) and resumed.target_weapon==family,"Checkpoint restores the promised family")
		var count: int = loaded.data.inventory.size()
		receipt = loaded.finish_attempt(attempt.id,{"victory":true,"target_weapon":"invalid"})
		var item: Dictionary = loaded.data.inventory.back()
		check(item.name==Run.Weapons.TYPES[family].name and item.level==1 and item.rarity in ["common","uncommon"],"Receipt uses the committed family and starter budget, never an outcome override")
		check(loaded.finish_attempt(attempt.id,{"victory":true}).is_empty() and loaded.data.inventory.size()==count+1,"Weapon reward cannot be duplicated")
		p = loaded
	var legacy = Run.new()
	legacy.configure_contract(p.stats(),"weapon")
	var legacy_save: Dictionary = legacy.snapshot()
	legacy_save.erase("target_weapon")
	check(Run.new().restore(legacy_save),"Existing contract checkpoints remain compatible")
	legacy_save.target_weapon = "invalid"
	check(not Run.new().restore(legacy_save),"Invalid stored weapon target is rejected")
	var clears_before_failure: int = p.data.contract_clears
	attempt = p.start_contract("helmet")
	r = Run.new(attempt.seed)
	r.configure_contract(p.stats(), "helmet")
	r.elapsed = 179.99
	r.field.caches_opened = 3
	r.extract_progress = 2.99
	r.player = Salvage.EXIT
	r.tick(0.02, Vector2.ZERO)
	check(r.phase == "defeat" and r.boss_id == -1, "Reaching the deadline fails before an unfinished extraction and never spawns a boss")
	var flow = Flow.new()
	check(not r.rescue() and flow.begin(attempt.id, r).is_empty(), "Expired contract cannot consume a video for an unusable rescue")
	r.field.add_loot("parts", "Parts", 3)
	r.field.add_loot("gear", "Boots", 1, "uncommon", "boots")
	r.field.set_secure(0, true)
	r.field.credits = 7
	receipt = p.finish_attempt(attempt.id, r.result())
	check(receipt.parts == 3 and receipt.credits == 7 and receipt.lost == 1 and receipt.gear.is_empty(), "Failed contract banks protected loot, not completion equipment")
	check(p.data.contract_clears == clears_before_failure and receipt.keys == 0, "Failure cannot advance the supply-key counter")
	r = Run.new()
	r.configure_contract(p.stats(), "weapon")
	r.elapsed = 70
	r.health = 0
	r.phase = "defeat"
	check(r.rescue() and r.elapsed == 70 and r.mode == "salvage", "Ordinary combat death permits one rescue without resetting the deadline")
	r = Run.new()
	r.configure(1, p.stats())
	r.elapsed = r.duration - 0.01
	r.tick(0.02, Vector2.ZERO)
	check(r.phase == "boss" and r.boss_id >= 0, "Campaign still spawns its mandatory boss at timer end")
	r.tick(20, Vector2.ZERO)
	check(r.phase != "victory", "Elapsed time alone cannot complete the campaign boss")
	# Exercise controller wiring, using the same isolated save as the rules checks.
	var arena = load("res://main.tscn").instantiate()
	arena.profile = Profile.new(PATH)
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.start_contract("body")
	check(arena.run.mode == "salvage" and not arena.home.visible and arena.attempt_id > 0, "Haven starts the actual contract controller")
	arena.run.field.caches_opened = 3
	arena.run.elapsed = 92
	arena.run.extract_progress = 1.0
	arena.show_haven()
	arena.resume_campaign()
	check(arena.run.mode == "salvage" and arena.run.paused and arena.run.extract_progress == 1.0, "Haven resume retains contract state and opens paused")
	arena.run.phase = "victory"
	arena.last_screen = ""
	arena.update_modal()
	check(arena.attempt_id == 0 and arena.reward_receipt.gear.size() == 1 and arena.profile.data.inventory.back().slot == "body", "Controller banks the chosen contract reward")
	arena.replay()
	check(arena.run.mode == "salvage" and arena.run.target_slot == "body", "Replay starts another contract for the same slot")
	arena.run.phase = "defeat"
	arena.bank_result()
	arena.last_screen = ""
	arena.update_modal()
	arena.show_haven()
	arena.home.navigate("contracts")
	arena.home.find_child("ContractWeapon_crossbow",true,false).pressed.emit()
	check(arena.home.contract_weapon=="crossbow","Weapon card selects the promised contract reward")
	for size_value in [Vector2i(320,568),Vector2i(430,760)]:
		root.size = size_value
		for frame in 6: await process_frame
		var last_card: Control = arena.home.find_child("ContractWeapon_sabre",true,false)
		check(last_card.get_global_rect().end.x <= arena.home.frame_panel.get_global_rect().end.x,"All five reward cards fit the phone width")
		check(arena.home.find_child("StartContract",true,false).get_global_rect().end.y < arena.home.navigation.position.y,"Contract start remains above navigation")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture=") and DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(argument.trim_prefix("--capture="))
	arena.home.find_child("StartContract",true,false).pressed.emit()
	check(arena.run.target_weapon=="crossbow" and arena.profile.data.active_attempt.target_weapon=="crossbow","Real home action starts the selected weapon contract")
	arena.run.phase = "victory"
	arena.last_screen = ""
	arena.update_modal()
	check(arena.profile.data.inventory.back().name=="Salvager Crossbow","Controller delivers the card's advertised item")
	arena.replay()
	check(arena.run.target_weapon=="crossbow","Replay preserves the weapon selection")
	arena.queue_free()
	await process_frame
	# Walk to real caches, survive actual AI, then charge extraction with starter stats.
	for seed_value in [41,73,109]:
		var route := Run.new(seed_value)
		route.configure_contract(Profile.new().stats(),"weapon","crossbow")
		for frame in 60*181:
			if route.phase=="upgrade": route.choose_offer(0)
			if route.phase=="shrine": route.leave_shrine()
			var direction := Review.contract_steer(route)
			for enemy: Dictionary in route.enemies:
				if enemy.tell>0 and enemy.tell<0.2 and enemy.pos.distance_to(route.player)<65:
					route.dodge()
			route.tick(1.0/60,direction)
			if route.phase in ["victory","defeat"]: break
		check(route.phase=="victory" and route.field.caches_opened>=3 and route.extract_progress>=3,"Real starter route can collect and extract, seed %d" % seed_value)
		check(route.health>0 and route.damage_taken>0 and route.kills>0 and route.boss_id==-1,"Route uses live combat without immunity or boss-rule leakage")
		print("Contract seed %d: %s at %.2fs; %d kills; %.1f HP" % [seed_value,route.phase,route.elapsed,route.kills,route.health])
	cleanup()
	print("Nightfall salvage contracts: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
