extends RefCounted
## Native illustrated preparation screens; progression data stays in the profile.
const Content = preload("res://combat_content.gd")
const Haven = preload("res://haven_content.gd")
const Showcase = preload("res://class_showcase.gd")
const Powers = preload("res://power_hud.gd")
const Talents = preload("res://class_talents.gd")
const BossArt = preload("res://boss_art.gd")
const TACTICS := [
	"Leave the Mauler's slam circle. Sidestep its marked charge lane.",
	"The Runner charges twice, then throws rubble. Dodge across the lane and strike during recovery.",
	"The Porchcaller summons a crowd. Clear it with area attacks and avoid the rubble fan.",
	"Scrapback blocks half of frontal physical damage. Circle behind it or use elemental attacks.",
	"The Breaker mixes charges, slams and rubble. Below half health it attacks faster; save Dodge for an escape."]
const BUILDS := {"Balanced": ["ember", "frost", "chain"], "Close range": ["wisp", "ground", "gravity"], "Projectiles": ["lance", "blades", "ember"]}

static func label_in(home: Control, parent: Node, value: String, size_value: int = 14, tint: Color = Color("d9e5ff")) -> Label:
	var label: Label = home.MenuSkin.label(parent, value, size_value, tint)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF if parent is HBoxContainer else TextServer.AUTOWRAP_WORD_SMART
	return label

static func card(home: Control, parent: Node, border: Color = Color("396baf"), inset: int = 9) -> VBoxContainer:
	var content: VBoxContainer = home.MenuSkin.panel(parent, "panel", maxi(12, inset))
	content.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 4)
	return content

static func art(home: Control, parent: Node, texture: Texture2D, dimensions: Vector2) -> TextureRect:
	var picture: TextureRect = home.MenuSkin.icon(parent, texture, dimensions)
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return picture

static func rail(home: Control, parent: Node, value: float, maximum: float, height: int = 8) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = maxf(1.0, maximum)
	bar.value = value
	bar.show_percentage = false
	bar.custom_minimum_size.y = height
	home.MenuSkin.progress(bar)
	for part in ["background", "fill"]:
		var face: StyleBox = bar.get_theme_stylebox(part).duplicate()
		face.set_content_margin_all(0)
		bar.add_theme_stylebox_override(part, face)
	parent.add_child(bar)
	return bar

static func title(home: Control, text_value: String, _icon: String = "") -> void:
	var ribbon := Control.new()
	ribbon.custom_minimum_size.y = 36
	home.body.add_child(ribbon)
	var image := art(home, ribbon, Showcase.texture("ribbon"), Vector2.ZERO)
	image.position = Vector2(28, 0)
	image.size = Vector2(330, 36)
	image.stretch_mode = TextureRect.STRETCH_SCALE
	Showcase.caption(ribbon, text_value, Rect2(45, 0, 296, 35), 24)

static func preview_path(home: Control, parent: Node, id: String) -> void:
	var path := Control.new()
	path.custom_minimum_size.y = 150
	parent.add_child(path)
	var points := [Vector2(39,57), Vector2(172,25), Vector2(172,98), Vector2(305,57)]
	for index in [1,2]:
		var edge := Line2D.new()
		edge.width = 2
		edge.default_color = Color("6baff0")
		edge.points = PackedVector2Array([points[0], points[index], points[3]])
		path.add_child(edge)
	var captions := ["Learn · Rank 1", Content.BRANCHES[id].focus.name, Content.BRANCHES[id].spread.name, "Evolve · Rank 3"]
	for index in points.size():
		var frame := art(home, path, Showcase.texture("portrait"), Vector2.ZERO)
		frame.position = points[index] - Vector2(23,23)
		frame.size = Vector2(46,46)
		frame.modulate = Color("ffdf9b") if index == 3 else Color.WHITE
		var icon := art(home, path, Powers.texture_for(id), Vector2.ZERO)
		icon.position = points[index] - Vector2(16,16)
		icon.size = Vector2(32,32)
		var caption := label_in(home, path, captions[index], 11, Color("ffe3a3") if index == 3 else Color("e4edff"))
		caption.autowrap_mode = TextServer.AUTOWRAP_OFF
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.position = points[index] + Vector2(-57,25)
		caption.size = Vector2(114,17)
	var note := Label.new()
	note.text = "Choose one specialization at rank 2"
	note.autowrap_mode = TextServer.AUTOWRAP_OFF
	note.add_theme_font_override("font", home.MenuSkin.body_font())
	note.add_theme_font_size_override("font_size", 12)
	note.position = Vector2(34,134)
	note.size = Vector2(280,18)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	path.add_child(note)

static func training(home: Control) -> void:
	title(home, "Training Yard", "training")
	var index: int = home.training_mission - 1
	var unlocked: bool = home.profile.practice_unlocked(home.training_mission)
	var stage := card(home, home.body, Color("6e5daf"), 6)
	label_in(home, stage, Haven.MISSIONS[index].boss, 21, Color("ffe0a4")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var portrait := art(home, stage, BossArt.texture(home.training_mission), Vector2(0, 146))
	portrait.name = "TrainingBossPortrait"
	var bosses := HBoxContainer.new()
	bosses.add_theme_constant_override("separation", 5)
	stage.add_child(bosses)
	for number in range(1, Haven.MISSIONS.size() + 1):
		var node: Button = home.button(str(number), func(): home.training_mission = number; home.rebuild(), bosses, 44)
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		node.icon = BossArt.texture(number)
		node.expand_icon = true
		node.add_theme_constant_override("icon_max_width", 29)
		node.tooltip_text = Haven.MISSIONS[number - 1].boss + ("" if home.profile.practice_unlocked(number) else " • not encountered")
		if home.training_mission == number:
			home.MenuSkin.action(node, "gold")
	var strategy := card(home, home.body)
	label_in(home, strategy, "BOSS TACTIC" if unlocked else "NOT ENCOUNTERED", 12, Color("bfa9f6"))
	label_in(home, strategy, TACTICS[index] if unlocked else "Encounter this boss in the campaign to unlock practice.", 14)
	var build := HBoxContainer.new()
	build.alignment = BoxContainer.ALIGNMENT_CENTER
	build.add_theme_constant_override("separation", 6)
	strategy.add_child(build)
	for ability: String in BUILDS[home.training_build]:
		art(home, build, Powers.texture_for(ability), Vector2(34, 34))
	var choose: Button = home.button(home.training_build, func():
		var options := BUILDS.keys()
		home.training_build = options[(options.find(home.training_build) + 1) % options.size()]
		home.rebuild(), build, 48)
	choose.custom_minimum_size.x = 148
	choose.tooltip_text = home.training_build + " · tap to change build"
	var start: Button = home.button("Practice boss", func(): home.practice_requested.emit(home.training_mission, home.training_build))
	start.disabled = not unlocked
	home.MenuSkin.action(start, "gold")
	home.text_line("Equipped gear · three rank-1 automatic spells\nFree practice. No loot, XP or campaign rewards.", 12)

static func arcanum(home: Control) -> void:
	var id: String = Powers.ORDER[home.guide_index]
	var evolution: Dictionary = Content.EVOLUTIONS[id]
	title(home, "Arcanum", "arcanum")
	var spell := card(home, home.body, Color("8770ca"), 8)
	var summary := HBoxContainer.new()
	spell.add_child(summary)
	art(home, summary, Powers.texture_for(id), Vector2(55, 55))
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_child(words)
	label_in(home, words, Content.SPELLS[id].name, 21, Color("ffdfa0"))
	label_in(home, words, "ABILITY %d / 8 · AUTOMATIC" % (home.guide_index + 1), 12, Color("baa9ed"))
	preview_path(home, spell, id)
	var branches := HBoxContainer.new()
	branches.add_theme_constant_override("separation", 7)
	home.body.add_child(branches)
	for branch in ["focus", "spread"]:
		var info: Dictionary = Content.BRANCHES[id][branch]
		var choice := card(home, branches, Color("6653a1"), 7)
		choice.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label_in(home, choice, info.name, 16, Color("cfb5ff"))
		label_in(home, choice, info.description, 12)
	var evolved := card(home, home.body, Color("b58a48"), 8)
	var final_row := HBoxContainer.new()
	evolved.add_child(final_row)
	art(home, final_row, Powers.texture_for(id), Vector2(38, 38))
	var final_words := VBoxContainer.new()
	final_words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	final_row.add_child(final_words)
	label_in(home, final_words, evolution.name, 18, Color("ffda92"))
	label_in(home, final_words, "Rank 3 + " + Content.PASSIVES[evolution.pair].name, 12)
	label_in(home, evolved, evolution.description, 12)
	var controls := HBoxContainer.new()
	controls.custom_minimum_size.x = 300
	controls.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	controls.add_theme_constant_override("separation", 8)
	home.body.add_child(controls)
	home.button("‹ Previous", func(): home.guide_index = (home.guide_index + 7) % 8; home.rebuild(), controls, 48).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home.button("Next ›", func(): home.guide_index = (home.guide_index + 1) % 8; home.rebuild(), controls, 48).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home.text_line("Unlock in Class → Skill tree. Build spell ranks anew each run.", 12)

static func mastery(home: Control) -> void:
	var id: String = home.inspected_class if not home.inspected_class.is_empty() else home.profile.data["class"]
	var xp: int = home.profile.data.mastery[id]
	var level: int = Haven.mastery_level(xp)
	title(home, "Mastery", "class")
	var summary := card(home, home.body, Color("8770ca"), 8)
	var top := HBoxContainer.new()
	summary.add_child(top)
	var portrait := art(home, top, Showcase.portrait_texture(id), Vector2(84, 84))
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.clip_contents = true
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(words)
	label_in(home, words, Haven.CLASSES[id].name, 21, Color("ffe1a8"))
	label_in(home, words, "Mastery %d / 20" % level, 18)
	var spent := level * (level + 1) * 50
	label_in(home, words, "%d / %d XP" % [xp - spent, (level + 1) * 100] if level < 20 else "Mastery complete", 12, Color("c0a9ef"))
	rail(home, summary, xp - spent if level < 20 else 1, (level + 1) * 100 if level < 20 else 1)
	var talents: Array = Talents.TALENTS.get(id, [])
	var scroll := ScrollContainer.new()
	scroll.name = "MasteryTalents"
	scroll.custom_minimum_size.y = 286 if not talents.is_empty() else 70
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	home.body.add_child(scroll)
	var milestones := VBoxContainer.new()
	milestones.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	milestones.add_theme_constant_override("separation", 7)
	scroll.add_child(milestones)
	for index in talents.size():
		var threshold: int = (index + 1) * 5
		var talent: Array = talents[index]
		var earned: bool = level >= threshold
		var entry := card(home, milestones, Color("ad8849") if earned else Color("3c557b"), 12)
		var row := HBoxContainer.new()
		entry.add_child(row)
		art(home, row, Powers.texture_for(Powers.ORDER[index]), Vector2(32, 32)).modulate = Color.WHITE if earned else Color("868ba8")
		var detail := VBoxContainer.new()
		detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(detail)
		label_in(home, detail, talent[0], 16, Color("ffe0a0") if earned else Color("c5cce4"))
		label_in(home, detail, talent[1], 12)
		label_in(home, row, "✓" if earned else str(threshold), 17, Color("ffe0a0") if earned else Color("a89bd4"))
	if talents.is_empty():
		label_in(home, summary, "This class is a preview. Its permanent talents are not available yet.", 14)
	home.text_line("Permanent XP from combat, clears and contracts.\nEarned mastery stays after defeat.", 12)
	home.button("Back to classes", func(): home.page = "class"; home.rebuild())
