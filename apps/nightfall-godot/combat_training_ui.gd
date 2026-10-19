extends RefCounted
## Permanent combat training presentation. Profile owns style and XP transactions.
const Progression = preload("res://combat_progression.gd")
const MenuSkin = preload("res://menu_skin.gd")
const Art = preload("res://haven_art.gd")
const UI = preload("res://preparation_ui.gd")
const Powers = preload("res://power_hud.gd")
const ORDER := ["attack", "strength", "defence", "ranged", "magic", "vitality"]
const STYLES := ["accurate", "powerful", "guarded", "ranged", "arcane", "balanced"]
const BONUS_KEYS := {"attack":"crit", "strength":"physical", "defence":"reduction", "ranged":"physical", "magic":"magic", "vitality":"hp"}
const BONUS_NAMES := {"attack":"Crit", "strength":"Physical", "defence":"Reduction", "ranged":"Physical", "magic":"Elemental", "vitality":"HP"}

static func show_page(home: Control) -> void:
	UI.title(home, "Combat Training")
	var experience: Dictionary = home.profile.data.combat_xp
	var summary := HBoxContainer.new()
	summary.add_theme_constant_override("separation", 8)
	home.body.add_child(summary)
	UI.art(home, summary, Art.icon("training"), Vector2(32,32))
	UI.label_in(home, summary, "Combat Level %d / 99" % Progression.combat_level(experience), 17, Color("ffe2a0")).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var points := UI.label_in(home, summary, "%d talent points" % home.profile.skill_points(home.profile.data["class"]), 14, Color("d8ecff"))
	points.name = "CombatTalentPoints"
	var stats := UI.card(home, home.body, Color("5799db"), 10)
	stats.name = "CombatStats"
	stats.add_theme_constant_override("separation", 5)
	for id: String in ORDER:
		stat_row(home, stats, id, experience)
	var focus := VBoxContainer.new()
	focus.add_theme_constant_override("separation", 4)
	home.body.add_child(focus)
	var choose := OptionButton.new()
	choose.name = "TrainingStyle"
	choose.custom_minimum_size = Vector2(300,44)
	choose.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	MenuSkin.action(choose, "blue")
	choose.add_theme_font_size_override("font_size", 16)
	focus.add_child(choose)
	var selected: String = home.profile.data.training_style
	for index in STYLES.size():
		var id: String = STYLES[index]
		var definition: Dictionary = Progression.STYLES[id]
		choose.add_item("Focus · " + definition.name, index)
		choose.set_item_metadata(index, id)
		if id == selected:
			choose.select(index)
	choose.disabled = not home.profile.can_change_loadout()
	choose.item_selected.connect(func(index: int):
		var saved: bool = home.profile.set_training_style(choose.get_item_metadata(index))
		home.message = "Training focus saved." if saved else (home.profile.error if not home.profile.error.is_empty() else "Training focus could not be saved.")
		home.rebuild())
	var definition: Dictionary = Progression.STYLES[selected]
	var hint := "Damage XP → " + skill_names(definition.skills)
	if selected == "balanced":
		hint += " equally"
	UI.label_in(home, focus, hint + ". Vitality also earns one-third XP.", 12, Color("c9dff8"))
	var note: Label = home.text_line("Permanent training stays after each run. Bonuses apply to your next mission. Run levels and spell ranks reset.", 12)
	note.name = "CombatTrainingNote"
	if not home.profile.can_change_loadout():
		note.text = "Finish your saved expedition to change training focus. Your earned combat XP stays permanent."
	home.button("Back to Class", func(): home.navigate("class"))

static func skill_names(values: Array) -> String:
	var names := PackedStringArray()
	for id: String in values:
		names.append(id.capitalize())
	return "/".join(names)

static func stat_row(home: Control, parent: Node, id: String, experience: Dictionary) -> void:
	var xp: float = experience[id]
	var level: int = Progression.level(xp)
	var base: float = Progression.threshold(level)
	var next: float = Progression.threshold(level + 1) if level < 99 else base
	var isolated := {}
	for stat: String in ORDER:
		isolated[stat] = xp if stat == id else 0.0
	var bonuses: Dictionary = Progression.bonuses(isolated)
	var bonus: float = bonuses[BONUS_KEYS[id]] * 100.0
	var row := HBoxContainer.new()
	row.name = "CombatStat_" + id
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	UI.art(home, row, stat_icon(id), Vector2(30,30))
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 1)
	row.add_child(words)
	var heading := HBoxContainer.new()
	words.add_child(heading)
	UI.label_in(home, heading, "%s · %s +%.1f%%" % [id.capitalize(), BONUS_NAMES[id], bonus], 13, Color("e5efff")).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rank := UI.label_in(home, heading, "%d / 99" % level, 14, Color("ffe3a0"))
	rank.name = "CombatLevel_" + id
	var progress := HBoxContainer.new()
	progress.add_theme_constant_override("separation", 6)
	words.add_child(progress)
	var bar: ProgressBar = UI.rail(home, progress, xp - base if level < 99 else 1, next - base if level < 99 else 1, 5)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var earned := UI.label_in(home, progress, "%.0f / %.0f XP" % [xp - base, next - base] if level < 99 else "MAX", 10, Color("c0d5ef"))
	earned.name = "CombatXP_" + id
	row.tooltip_text = "%.0f total %s XP. %s contribution: +%.1f%%. Bonuses activate next mission." % [xp, id.capitalize(), BONUS_NAMES[id], bonus]
	if id == "attack":
		row.tooltip_text += " Critical hits deal 1.5× damage."
	elif id in ["strength", "ranged"]:
		row.tooltip_text += " Strength and Ranged physical bonuses add together."

static func stat_icon(id: String) -> Texture2D:
	match id:
		"attack": return Art.SWORD
		"strength": return Art.icon("training")
		"defence": return Art.SHIELD
		"ranged": return Art.item("weapon")
		"magic": return Powers.texture_for("gravity")
	return Art.item("hp")
