extends SceneTree

const Run = preload("res://run.gd")
const Flow = preload("res://reward_flow.gd")
const Profile = preload("res://profile.gd")
var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func _initialize() -> void:
	var r = Run.new()
	var p = Profile.new()
	r.configure(1, p.stats())
	var flow = Flow.new()
	check(flow.begin(1, r).is_empty(), "Cannot request a rescue before defeat")
	r.health = 0
	r.phase = "defeat"
	r.field.add_loot("parts", "Parts", 3)
	r.field.scrap = 28
	r.elapsed = 130
	r.spells.ember = {"rank": 2, "wait": 3.0}
	var token: String = flow.begin(1, r)
	check(not token.is_empty() and flow.begin(1, r).is_empty(), "Only one video request can be pending")
	check(not flow.earned("wrong", 1, r) and not flow.earned(token, 2, r), "Unrelated or stale expedition callbacks grant nothing")
	check(flow.fail(token, "No fill") and r.health == 0 and not r.rescued, "Ad load failure neither consumes rescue nor revives")
	token = flow.begin(1, r)
	check(flow.finish(token) and r.health == 0 and not r.rescued, "Early dismissal earns no rescue")
	check(not flow.earned(token, 1, r), "An ended request cannot later grant a reward")
	token = flow.begin(1, r)
	check(flow.earned(token, 1, r), "Matching earned callback grants rescue")
	check(r.health == 105 and r.paused and r.phase == "waves" and r.rescued, "Rescue restores fifty percent and waits for explicit resume")
	check(r.elapsed == 130 and r.spells.ember.rank == 2 and r.field.bag.size() == 1 and r.field.scrap == 28, "Rescue preserves timer, powers and carried loot")
	check(not flow.earned(token, 1, r) and r.health == 105, "Duplicate earned callback cannot heal twice")
	check(flow.finish(token), "Video closure completes earned request")
	r.paused = false
	r.hurt(200)
	check(r.health == 105, "Brief rescue protection prevents immediate repeat death")
	r.phase = "defeat"
	r.health = 0
	check(flow.begin(1, r).is_empty() and not r.rescue(), "Second defeat cannot obtain a second rescue")
	check(r.result().rescued, "Mission result retains rescue flag for mastery eligibility")
	var restored = Run.new()
	check(restored.restore(r.snapshot()) and restored.rescued and not restored.rescue(), "Reload cannot reset the once-per-attempt rescue")
	r = Run.new()
	r.configure(2, p.stats())
	r.spawn_enemy(true)
	r.phase = "defeat"
	check(r.rescue() and r.phase == "boss", "Boss rescue returns to boss phase without restarting the mission")
	r = Run.new()
	r.start_boss_practice()
	r.phase = "defeat"
	check(not r.rescue(), "Practice cannot earn campaign ad rewards")
	print("Nightfall rewarded rescue: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
