extends SceneTree

const Run = preload("res://run.gd")
const Field = preload("res://field.gd")
var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func _initialize() -> void:
	var f = Field.new(7)
	check(f.sites.filter(func(s: Dictionary): return s.kind == "shop").size() == 1 and f.sites.filter(func(s: Dictionary): return s.kind == "relic").size() == 2, "One shop and two relic shrines")
	f.tick(1.9, Field.interaction_center(f.sites[0]))
	check(f.active_site == -1, "Shop requires full two seconds")
	f.tick(0.11, Field.interaction_center(f.sites[0]))
	check(f.active_site == 0, "Proximity completion opens shop")
	check(not f.buy_trait("vitality"), "Cannot buy without Field Scrap")
	f.scrap = 140
	check(f.buy_trait("vitality") and f.buy_trait("vitality") and f.buy_trait("vitality"), "Several purchases during one shop visit")
	check(f.scrap == 0 and f.traits.vitality == 3 and not f.buy_trait("vitality"), "Costs 30+45+65, rank capped at three")
	f.leave()
	f.tick(5, Field.interaction_center(f.sites[0]))
	check(f.active_site == -1, "Leaving a shrine does not instantly reopen it under the player")
	f.tick(0.1, Vector2.ZERO)
	f.tick(2, Field.interaction_center(f.sites[0]))
	check(f.active_site == 0, "Shop can be revisited after stepping away")
	f.leave()
	f.tick(6, Field.interaction_center(f.sites[1]))
	check(f.active_site == -1 and f.sites[1].progress == 6, "Relic requires seven seconds")
	f.tick(0.5, Vector2.ZERO)
	check(f.sites[1].progress == 6, "Brief exit preserves charge")
	f.tick(1.5, Vector2.ZERO)
	check(f.sites[1].progress < 6, "After grace charge drains outside circle")
	f.tick(7, Field.interaction_center(f.sites[1]))
	check(f.active_site == 1 and f.sites[1].offers.size() == 2, "Twinflame offers two choices")
	var original: Array = f.sites[1].offers.duplicate()
	f.leave()
	f.tick(0.1, Vector2.ZERO)
	f.tick(7, Field.interaction_center(f.sites[1]))
	check(f.sites[1].offers == original, "Reopening cannot reroll for free")
	f.scrap = 30
	check(f.reroll() and f.scrap == 20 and f.sites[1].offers != original, "First reroll spends ten scrap and changes offers")
	check(f.reroll() and f.scrap == 0 and not f.reroll(), "Second costs twenty, no third reroll")
	f.choose_relic(0)
	check(f.relics.size() == 1 and f.sites[1].cooldown == 45 and f.active_site == -1, "Relic acceptance consumes one shared allowance and rests shrine")
	f.tick(7, Field.interaction_center(f.sites[2]))
	f.choose_relic(0)
	f.tick(45, Vector2.ZERO)
	f.tick(7, Field.interaction_center(f.sites[1]))
	f.choose_relic(0)
	check(f.relics.size() == 3 and f.relics[0] != f.relics[1] and f.relics[1] != f.relics[2], "Relics are unique across both shrines")
	f.tick(60, Field.interaction_center(f.sites[2]))
	check(f.active_site == -1, "Shared limit stops a fourth relic")
	f = Field.new()
	for i in 8:
		f.add_loot("parts", "Parts", i + 1)
	check(not f.add_loot("parts", "Overflow") and f.bag.size() == 8, "Protected slots count inside eight-slot bag")
	check(f.set_secure(0, true) and f.set_secure(1, true) and not f.set_secure(2, true), "Only two protected slots")
	check(not f.discard(0) and f.discard(7), "Protected items cannot be accidentally discarded")
	check(f.banked_loot(false).size() == 2 and f.banked_loot(true).size() == 7, "Defeat returns protected loot, victory returns entire pack")
	f.open_cache(3)
	var credits: int = f.credits
	f.open_cache(3)
	check(f.caches_opened == 1 and f.credits == credits, "Cache rewards only once")
	f.open_cache(4)
	check(not f.sites[4].opened, "Full bag does not consume cache")
	var r = Run.new()
	r.player = Field.interaction_center(r.field.sites[0])
	r.spawn_wait = 100
	r.field.scrap = 30
	r.tick(2, Vector2.ZERO)
	check(r.phase == "shrine" and r.elapsed == 2, "Combat and clock continue while charging")
	r.tick(3, Vector2.RIGHT)
	check(r.elapsed == 2, "Choice menu pauses the simulation")
	check(r.buy_trait("vitality") and r.max_health() == 132 and r.health == 132, "Vitality changes cap and restores only added health")
	r.leave_shrine()
	check(r.phase == "waves", "Leaving resumes proper phase")
	r.field.relics.append("obsidian")
	r.hurt(20)
	check(is_equal_approx(r.health, 114), "Obsidian reduces damage by ten percent")
	r.field.relics.append("emberleaf")
	r.spawn_wait = 100
	r.tick(3, Vector2.ZERO)
	check(is_equal_approx(r.health, 114), "Emberleaf cannot heal immediately after damage")
	r.player = Vector2.ZERO
	r.tick(1, Vector2.ZERO)
	check(r.health > 114 and r.health < 115, "Emberleaf heals a bounded fraction after quiet period")
	r.open_pack()
	var before: float = r.elapsed
	r.tick(1, Vector2.RIGHT)
	check(r.phase == "pack" and r.elapsed == before, "Backpack pauses combat")
	r.close_pack()
	check(r.phase == "waves", "Pack returns to combat")
	print("Nightfall exploration: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
