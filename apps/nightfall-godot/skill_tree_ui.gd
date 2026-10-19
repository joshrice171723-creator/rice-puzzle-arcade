extends RefCounted
const Skills = preload("res://skill_tree.gd")
const Content = preload("res://combat_content.gd")
const Haven = preload("res://haven_content.gd")
const Powers = preload("res://power_hud.gd")

static func show_tree(home: Control) -> void:
	var profile: RefCounted = home.profile
	var class_id: String = home.inspected_class if not home.inspected_class.is_empty() else profile.data["class"]
	var learned: Array = profile.data.skill_unlocks[class_id]
	var pool: Array = profile.ability_pool(class_id)
	var id: String = home.tree_ability
	if id not in Content.SPELLS:
		id = Skills.STARTERS[class_id][0]
	var points: int = profile.skill_points(class_id)
	home.text_line("%s skills · %d points" % [Haven.CLASSES[class_id].name, points], 22)
	home.text_line("Unlock possible level-up choices. Learn and upgrade them again each run. Earn 1 point per mastery level through level 9.", 12)
	var diagram := Control.new()
	diagram.name = "ClassSkillTree"
	diagram.custom_minimum_size.y = 218
	home.body.add_child(diagram)
	var positions: Dictionary = {}
	for index in 3:
		positions[Skills.STARTERS[class_id][index]] = Vector2(index * 130, 0)
	var branch: Array = Skills.BRANCHES[class_id]
	for index in 5:
		positions[branch[index]] = Vector2(130 if index == 4 else (index % 2) * 190 + 35, 56 + (index / 2) * 56)
	for ability: String in branch:
		for parent: String in Skills.parents(class_id, ability):
			var edge := Line2D.new()
			edge.width = 2
			edge.default_color = Color("78adff") if parent in pool else Color("60667e")
			edge.points = PackedVector2Array([positions[parent] + Vector2(59, 44), positions[ability] + Vector2(59, 0)])
			diagram.add_child(edge)
	for ability: String in positions:
		var starter: bool = ability in Skills.STARTERS[class_id]
		var owned: bool = ability in pool
		var price: int = Skills.cost(class_id, ability)
		var node: Button = home.button(Content.SPELLS[ability].name, func(): home.tree_ability = ability; home.message = ""; home.rebuild(), diagram, 44)
		node.name = "Skill_" + ability
		node.position = positions[ability]
		node.size = Vector2(118, 44)
		node.add_theme_font_size_override("font_size", 10)
		node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		node.icon = Powers.texture_for(ability)
		node.expand_icon = true
		node.add_theme_constant_override("icon_max_width", 24)
		node.tooltip_text = Content.SPELLS[ability].name + (" · Starter" if starter else (" · Unlocked" if owned else " · %d points" % price))
		var border := Color("ffd27c") if ability == id else (Color("78adff") if owned else Color("60667e"))
		node.add_theme_stylebox_override("normal", home.style(Color("123b79") if owned else Color("20263b"), border))
	var description: Label = home.text_line(Content.SPELLS[id].name + "\n" + Content.SPELLS[id].description, 13)
	description.custom_minimum_size.y = 58
	var requirement := "Starter ability · available in level-up choices"
	if id not in Skills.STARTERS[class_id]:
		var names := PackedStringArray()
		for parent: String in Skills.parents(class_id, id):
			names.append(Content.SPELLS[parent].name)
		requirement = "Unlocked · available in level-up choices" if id in learned else "Needs: " + " + ".join(names)
	home.text_line(requirement, 12, Color("ba92ff"))
	var actions := HBoxContainer.new()
	home.body.add_child(actions)
	var cost: int = Skills.cost(class_id, id)
	var unlock: Button = home.button("Already unlocked" if id in pool else "Unlock · %d points" % cost, func(): home.refresh(func(): return profile.unlock_skill(class_id, id), Content.SPELLS[id].name + " added to this class's level-up pool."), actions)
	unlock.name = "UnlockSkill"
	unlock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unlock.disabled = id in pool or not profile.can_change_loadout() or not profile.class_unlocked(class_id) or points < cost or not Skills.prerequisites_met(class_id, id, learned)
	home.button("Back to Class", func(): home.navigate("class"), actions).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not profile.class_unlocked(class_id):
		home.text_line(Haven.CLASSES[class_id].unlock, 12)
