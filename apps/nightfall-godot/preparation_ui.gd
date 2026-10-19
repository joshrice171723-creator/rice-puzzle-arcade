extends RefCounted
## Preparation screens share the same definitions used by combat.
const Content = preload("res://combat_content.gd")
const Haven = preload("res://haven_content.gd")
const Diagram = preload("res://ability_path.gd")
const Powers = preload("res://power_hud.gd")
const TACTICS := [
	"The Mauler's circular slam lands around its body. Leave the circle; sidestep its marked charge lane.",
	"The Runner charges twice before throwing rubble. Dodge across the lane, then attack during its longer recovery.",
	"The Porchcaller summons reinforcements. Area attacks clear the crowd; leave space to avoid its rubble fan.",
	"Scrapback blocks half of frontal physical damage. Circle behind it or use elemental attacks while avoiding its slam.",
	"The Breaker mixes charges, slams and rubble fans. Below half health its attacks accelerate. Save Dodge for a blocked escape."]
const BUILDS := {"Balanced": ["ember", "frost", "chain"], "Close range": ["wisp", "ground", "gravity"], "Projectiles": ["lance", "blades", "ember"]}

static func training(home: Control) -> void:
	home.text_line("TRAINING YARD", 22, Color("ffd27c"))
	home.text_line("Practice an encountered boss with your equipped gear. No entry cost, loot, XP or campaign rewards.", 13)
	var bosses := HBoxContainer.new()
	home.body.add_child(bosses)
	for index in Haven.MISSIONS.size():
		var number := index + 1
		var unlocked: bool = home.profile.practice_unlocked(number)
		var node: Button = home.button(str(number) + (" ◆" if home.training_mission == number else ""), func(): home.training_mission = number; home.rebuild(), bosses)
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		node.tooltip_text = Haven.MISSIONS[index].boss + ("" if unlocked else " • not encountered")
	home.text_line(Haven.MISSIONS[home.training_mission - 1].boss, 23, Color("ba92ff"))
	if not home.profile.practice_unlocked(home.training_mission):
		home.text_line("Encounter this boss in the campaign to unlock practice.", 13)
	home.text_line(TACTICS[home.training_mission - 1], 13)
	home.button("Build: %s • change" % home.training_build, func():
		var options := BUILDS.keys()
		home.training_build = options[(options.find(home.training_build) + 1) % options.size()]
		home.rebuild(), null, 40)
	var start: Button = home.button("Practice boss", func(): home.practice_requested.emit(home.training_mission, home.training_build))
	start.disabled = not home.profile.practice_unlocked(home.training_mission)
	home.text_line("Three automatic rank-1 spells. Dodge remains manual.", 12)

static func arcanum(home: Control) -> void:
	var id: String = Powers.ORDER[home.guide_index]
	var evolution: Dictionary = Content.EVOLUTIONS[id]
	home.text_line("ARCANUM • %d/8" % (home.guide_index + 1), 18, Color("ffd27c"))
	home.text_line(Content.SPELLS[id].name, 23, Color("ba92ff"))
	home.text_line("Plan your expedition. Learn spells from combat levels; this guide does not equip or unlock them.", 12)
	var path := Diagram.new()
	path.ability = id
	home.body.add_child(path)
	for branch in ["focus", "spread"]:
		var info: Dictionary = Content.BRANCHES[id][branch]
		home.text_line(info.name + ": " + info.description, 12)
	home.text_line(evolution.name + " • rank 3 + " + Content.PASSIVES[evolution.pair].name, 14, Color("ffd27c"))
	home.text_line(evolution.description, 12)
	var controls := HBoxContainer.new()
	home.body.add_child(controls)
	home.button("‹ Previous", func(): home.guide_index = (home.guide_index + 7) % 8; home.rebuild(), controls).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home.button("Next ›", func(): home.guide_index = (home.guide_index + 1) % 8; home.rebuild(), controls).size_flags_horizontal = Control.SIZE_EXPAND_FILL
