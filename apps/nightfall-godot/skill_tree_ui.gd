extends RefCounted
const Skills = preload("res://skill_tree.gd")
const Content = preload("res://combat_content.gd")
const Haven = preload("res://haven_content.gd")
const Powers = preload("res://power_hud.gd")
const UI = preload("res://preparation_ui.gd")
const Showcase = preload("res://class_showcase.gd")

static func show_tree(home: Control) -> void:
	var profile: RefCounted = home.profile
	var class_id: String = home.inspected_class if not home.inspected_class.is_empty() else profile.data["class"]
	var learned: Array = profile.data.skill_unlocks[class_id]
	var pool: Array = profile.ability_pool(class_id)
	var id: String = home.tree_ability
	if id not in Content.SPELLS:
		id = Skills.STARTERS[class_id][0]
	var points: int = profile.skill_points(class_id)
	UI.title(home, "Skill Tree", "arcanum")
	var summary := HBoxContainer.new()
	home.body.add_child(summary)
	var portrait := UI.art(home, summary, Showcase.portrait_texture(class_id), Vector2(40,40))
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.clip_contents = true
	UI.label_in(home, summary, Haven.CLASSES[class_id].name, 17, Color("dcc4ff")).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.label_in(home, summary, "%d POINTS" % points, 17, Color("ffdb92"))
	var diagram := Control.new()
	diagram.name = "ClassSkillTree"
	diagram.custom_minimum_size.y = 266
	home.body.add_child(diagram)
	var backdrop := Panel.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backdrop.add_theme_stylebox_override("panel", home.MenuSkin.surface("panel"))
	diagram.add_child(backdrop)
	var positions: Dictionary = {}
	for index in 3:
		positions[Skills.STARTERS[class_id][index]] = Vector2(14 + index * 130, 12)
	var branch: Array = Skills.BRANCHES[class_id]
	for index in 5:
		positions[branch[index]] = Vector2(144 if index == 4 else (index % 2) * 190 + 49, 78 + (index / 2) * 60)
	for ability: String in branch:
		for parent: String in Skills.parents(class_id, ability):
			var edge := Line2D.new()
			edge.width = 3
			edge.default_color = Color("b78af4") if ability in pool else (Color("727fae") if parent in pool else Color("293d68"))
			var source: Vector2 = positions[parent] + Vector2(74, 22)
			var end: Vector2 = positions[ability] + Vector2(54, 22)
			var bend_x: float = positions[parent].x + 110
			edge.points = PackedVector2Array([source, Vector2(bend_x, source.y), Vector2(bend_x, end.y), end])
			diagram.add_child(edge)
	for ability: String in positions:
		var starter: bool = ability in Skills.STARTERS[class_id]
		var owned: bool = ability in pool
		var price: int = Skills.cost(class_id, ability)
		var node: Button = home.button("", func(): home.tree_ability = ability; home.message = ""; home.rebuild(), diagram, 60)
		node.name = "Skill_" + ability
		node.position = positions[ability]
		node.size = Vector2(108, 60)
		node.tooltip_text = Content.SPELLS[ability].name + (" · Starter" if starter else (" · Unlocked" if owned else " · %d points" % price))
		for state in ["normal", "hover", "pressed", "disabled"]:
			node.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		var frame := UI.art(home, node, Showcase.texture("portrait"), Vector2.ZERO)
		frame.position = Vector2(32, 0)
		frame.size = Vector2(44, 44)
		frame.modulate = Color("ffdc87") if ability == id else (Color.WHITE if owned else Color("8191b4"))
		var picture := UI.art(home, node, Powers.texture_for(ability), Vector2.ZERO)
		picture.position = Vector2(39, 7)
		picture.size = Vector2(30, 30)
		picture.modulate = Color.WHITE if owned else Color("8e93b3")
		var caption := UI.label_in(home, node, Content.SPELLS[ability].name, 10, Color("fff1c8") if ability == id else Color("e3eaff"))
		caption.position = Vector2(2, 43)
		caption.size = Vector2(104, 17)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.autowrap_mode = TextServer.AUTOWRAP_OFF
		caption.max_lines_visible = 1
		caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		caption.add_theme_font_size_override("font_size", 11 if Content.SPELLS[ability].name.length() > 16 else 12)
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var badge := PanelContainer.new()
		badge.position = Vector2(58,27)
		badge.size = Vector2(18,16)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var badge_face := StyleBoxFlat.new()
		badge_face.bg_color = Color("12366d")
		badge_face.border_color = Color("edc16b") if owned else Color("79b5ec")
		badge_face.set_border_width_all(1)
		badge_face.set_corner_radius_all(3)
		badge.add_theme_stylebox_override("panel", badge_face)
		node.add_child(badge)
		var status := UI.label_in(home, badge, "✓" if owned else str(price), 10, Color("ffe2a0") if owned else Color.WHITE)
		status.autowrap_mode = TextServer.AUTOWRAP_OFF
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var selected := UI.card(home, home.body, Color("9772cd"), 8)
	var details := HBoxContainer.new()
	selected.add_child(details)
	UI.art(home, details, Powers.texture_for(id), Vector2(58, 58))
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_child(words)
	UI.label_in(home, words, Content.SPELLS[id].name, 19, Color("ffe1a1"))
	UI.label_in(home, words, Content.SPELLS[id].description, 12)
	var requirement := "Starter · available in level-up choices"
	if id not in Skills.STARTERS[class_id]:
		var names := PackedStringArray()
		for parent: String in Skills.parents(class_id, id):
			names.append(Content.SPELLS[parent].name)
		requirement = "Unlocked · available in level-up choices" if id in learned else "Needs " + " + ".join(names)
	if not profile.class_unlocked(class_id):
		requirement = Haven.CLASSES[class_id].unlock
	UI.label_in(home, selected, requirement, 12, Color("c6b1ed"))
	var actions := HBoxContainer.new()
	actions.custom_minimum_size.x = 336
	actions.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	actions.add_theme_constant_override("separation", 8)
	home.body.add_child(actions)
	var cost: int = Skills.cost(class_id, id)
	var unlock: Button = home.button("Already unlocked" if id in pool else "Unlock · %d points" % cost, func(): home.refresh(func(): return profile.unlock_skill(class_id, id), Content.SPELLS[id].name + " added to this class's level-up pool."), actions, 48)
	unlock.name = "UnlockSkill"
	unlock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unlock.disabled = id in pool or not profile.can_change_loadout() or not profile.class_unlocked(class_id) or points < cost or not Skills.prerequisites_met(class_id, id, learned)
	home.MenuSkin.action(unlock, "gold")
	home.button("Back to Class", func(): home.navigate("class"), actions, 48).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home.text_line("Unlock choices here. Spell ranks reset each run.", 12)
	summary.tooltip_text = "Earn 1 point per mastery level through level 9. Unlocks persist between expeditions."
