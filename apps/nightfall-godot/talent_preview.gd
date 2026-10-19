extends RefCounted
## Read-only class talent preview. Unlocks remain in the existing skill tree.
const Showcase = preload("res://class_showcase.gd")
const Art = preload("res://haven_art.gd")
const MenuSkin = preload("res://menu_skin.gd")
const Skills = preload("res://skill_tree.gd")
const Combat = preload("res://combat_content.gd")
const Content = preload("res://haven_content.gd")
const Powers = preload("res://power_hud.gd")

static func show_page(home: Control) -> void:
	var id: String = home.inspected_class if not home.inspected_class.is_empty() else home.profile.data["class"]
	var pool: Array = home.profile.ability_pool(id)
	var available: bool = home.profile.class_unlocked(id)
	var selected: String = home.tree_ability
	if selected not in Skills.STARTERS[id] and selected not in Skills.BRANCHES[id]:
		selected = Skills.STARTERS[id][0]
	var page := Control.new()
	page.name = "TalentPreview"
	page.custom_minimum_size = Vector2(386,598)
	home.body.add_child(page)
	var ribbon := Art.picture(page, Showcase.texture("ribbon"), Rect2(36,0,314,38))
	ribbon.stretch_mode = TextureRect.STRETCH_SCALE
	Showcase.caption(page,"Talent Preview",Rect2(66,0,254,35),24)
	var hero := Art.picture(page, Showcase.portrait_texture(id), Rect2(53,40,100,91))
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	hero.clip_contents = true
	Showcase.caption(page,Content.CLASSES[id].name,Rect2(157,44,175,30),24)
	var xp: int = home.profile.data.mastery[id]
	var level: int = Content.mastery_level(xp)
	Showcase.caption(page,"Mastery %d" % level,Rect2(160,75,169,23),15)
	Showcase.caption(page,"%d skill points" % home.profile.skill_points(id),Rect2(160,99,169,22),14,Color("ffe3a0"))
	for direction in [-1,1]:
		var change := Showcase.fixed_button(home,page,"‹" if direction < 0 else "›",Rect2(4 if direction < 0 else 342,65,40,48),func():
			var next: int = posmod(Showcase.ORDER.find(id)+direction,Showcase.ORDER.size())
			home.inspected_class=Showcase.ORDER[next]; home.tree_ability=""; home.rebuild(),false,27)
		change.name = "PreviousTalentClass" if direction < 0 else "NextTalentClass"
	for index in Showcase.ORDER.size():
		var class_id: String = Showcase.ORDER[index]
		var slot := Showcase.fixed_button(home,page,"",Rect2(10+94*index,135,84,65),func(): home.inspected_class=class_id; home.tree_ability=""; home.rebuild())
		slot.name = "TalentClass_"+class_id
		for state in ["normal","hover","pressed","disabled"]:
			slot.add_theme_stylebox_override(state,StyleBoxEmpty.new())
		var picture := Art.picture(slot,Showcase.portrait_texture(class_id),Rect2(4,3,76,53))
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		picture.clip_contents = true
		var border := Art.picture(slot,Showcase.texture("portrait"),Rect2(0,0,84,58))
		border.stretch_mode = TextureRect.STRETCH_SCALE
		border.modulate = Color("ffdf83") if class_id == id else Color.WHITE
		Showcase.caption(slot,Content.CLASSES[class_id].name,Rect2(0,54,84,16),11)
	var tree := Panel.new()
	tree.name = "TalentConstellation"
	tree.position = Vector2(3,209)
	tree.size = Vector2(380,298)
	tree.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tree.add_theme_stylebox_override("panel",MenuSkin.surface("inset"))
	page.add_child(tree)
	Showcase.caption(tree,"Class Talents",Rect2(65,5,250,25),21)
	var positions: Dictionary = {}
	for index in 3:
		positions[Skills.STARTERS[id][index]] = Vector2(52+136*index,67)
	var branch: Array = Skills.BRANCHES[id]
	for index in 5:
		positions[branch[index]] = Vector2(188 if index == 4 else 112+152*(index%2), 249 if index == 4 else 128+61*(index/2))
	for ability: String in branch:
		for parent: String in Skills.parents(id,ability):
			var start: Vector2 = positions[parent]
			var finish: Vector2 = positions[ability]
			for width in [7,2]:
				var line := Line2D.new()
				line.width = width
				line.default_color = Color(0.25,0.68,1.0,0.19) if width == 7 else (Color("82d8ff") if parent in pool else Color("4b628b"))
				line.points = PackedVector2Array([start,Vector2(start.x, (start.y+finish.y)*0.5),Vector2(finish.x,(start.y+finish.y)*0.5),finish])
				tree.add_child(line)
	for ability: String in positions:
		var owned: bool = ability in pool and available
		var node := Showcase.fixed_button(home,tree,"",Rect2(positions[ability]-Vector2(24,24),Vector2(48,48)),func(): home.tree_ability=ability; home.rebuild())
		node.name = "TalentNode_"+ability
		node.tooltip_text = Combat.SPELLS[ability].name + (" · Unlocked" if owned else " · Locked")
		var circle := StyleBoxTexture.new()
		circle.texture = MenuSkin.texture("selected" if ability == selected else "medallion")
		circle.set_content_margin_all(0)
		for state in ["normal","hover","pressed"]:
			node.add_theme_stylebox_override(state,circle)
		var icon := Art.picture(node,Powers.texture_for(ability),Rect2(9,9,30,30))
		icon.modulate = Color.WHITE if owned else Color("69758f")
		if not owned:
			var badge := Showcase.caption(node,str(Skills.cost(id,ability)) if available else "—",Rect2(32,31,16,17),10)
			badge.tooltip_text = "%d points to unlock" % Skills.cost(id,ability) if available else Content.CLASSES[id].unlock
	var state := "Unlocked" if selected in pool and available else ("%d points · Locked" % Skills.cost(id,selected) if available else "Class locked")
	Showcase.caption(page,Combat.SPELLS[selected].name+" · "+state,Rect2(4,511,378,23),14,Color("ffe2a2"))
	var details := Showcase.fixed_button(home,page,"Skill Tree",Rect2(9,548,180,44),func(): home.page="skills"; home.tree_ability=selected; home.rebuild())
	details.name = "TalentPreviewOpenTree"
	var mastery := Showcase.fixed_button(home,page,"Mastery",Rect2(197,548,180,44),func(): home.navigate("mastery"),true)
	mastery.name = "TalentPreviewOpenMastery"
