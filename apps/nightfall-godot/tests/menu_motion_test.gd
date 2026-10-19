extends SceneTree
## Motion integration must not touch the campaign or keep running behind combat.
var checks := 0
var failures := 0
func check(value: bool, words: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(words)
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var arena = load("res://main.tscn").instantiate()
	arena.testing = true
	root.add_child(arena)
	arena.set_physics_process(false)
	var home: Control = arena.home
	home.show()
	var before: Dictionary = arena.profile.data.duplicate(true)
	arena.profile.data.settings.reduced_effects = false
	home.navigate("gear")
	await process_frame
	var ambient = home.get_node_or_null("BackgroundMotion")
	var hero = home.find_child("EquippedHero", true, false)
	check(ambient != null, "Standard menu creates ambient effects")
	check(hero != null and hero.weapon_family==arena.profile.stats().weapon, "Gear showcases the actual equipped weapon")
	var idle = hero
	var feet: Vector2 = hero.position
	await create_timer(0.1).timeout
	check(idle.elapsed > 0 and hero.position == feet, "Idle advances without moving grounded portrait")
	home.hide()
	await process_frame
	var paused: float = ambient.elapsed
	await create_timer(0.1).timeout
	check(not ambient.is_processing() and is_equal_approx(ambient.elapsed, paused), "Hidden home stops ambient processing and time")
	check(not idle.is_processing(),"Hidden Gear stops character mesh animation")
	home.show()
	await create_timer(0.1).timeout
	check(ambient.elapsed > paused, "Visible home resumes motion")
	for page in ["mission", "haven"]:
		home.navigate(page)
		check(home.find_child("IslandMotion", true, false) != null, page + " has island effects")
	arena.profile.data.settings.reduced_effects = true
	for page in ["gear","mission","haven","class"]:
		home.navigate(page)
		check(home.get_node_or_null("BackgroundMotion") == null, page + " respects Reduced effects for atmosphere")
		check(home.find_child("IslandMotion", true, false) == null and home.find_child("HeroIdle", true, false) == null, page + " respects Reduced effects for art")
		if page=="gear":
			check(not home.find_child("EquippedHero",true,false).is_processing(),"Reduced effects freezes Gear body and weapon")
	arena.profile.data.settings.reduced_effects = before.settings.reduced_effects
	check(arena.profile.data == before and arena.attempt_id == 0, "Menu effects never modify campaign, wallet, equipment or attempt")
	print("Nightfall menu motion: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
