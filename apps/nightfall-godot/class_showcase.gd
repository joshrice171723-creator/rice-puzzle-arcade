extends RefCounted
## Hero-first Class screen. All progression and selection remain profile-owned.
const Art = preload("res://haven_art.gd")
const Content = preload("res://haven_content.gd")
const MenuSkin = preload("res://menu_skin.gd")
const Portrait = preload("res://class_portrait.gd")
const HALL = preload("res://assets/class-showcase/hall.png")
const CONTROLS = preload("res://assets/class-showcase/controls.png")
const ORDER := ["scavenger", "warden", "arcanist", "engineer"]
const REGIONS := {"blue": Rect2i(40,219,559,142), "gold": Rect2i(657,219,560,142), "portrait": Rect2i(82,662,480,467), "ribbon": Rect2i(627,836,606,123)}
static var textures: Dictionary = {}

static func texture(kind: String) -> Texture2D:
	if not textures.has(kind):
		var pixels := CONTROLS.get_image().get_region(REGIONS[kind])
		var width := 128 if kind == "portrait" else 256
		pixels.resize(width, roundi(pixels.get_height() * float(width) / pixels.get_width()), Image.INTERPOLATE_LANCZOS)
		textures[kind] = ImageTexture.create_from_image(pixels)
	return textures[kind]

static func face(kind: String = "blue") -> StyleBoxTexture:
	var result := StyleBoxTexture.new()
	result.texture = texture(kind)
	result.set_texture_margin_all(12 if kind == "portrait" else 14)
	result.set_content_margin_all(7)
	return result

static func action(button: Button, gold: bool = false, font_size: int = 19) -> void:
	var normal := face("gold" if gold else "blue")
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.modulate_color = Color(1.12,1.12,1.12)
	button.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate()
	pressed.modulate_color = Color("b0c5e8")
	button.add_theme_stylebox_override("pressed", pressed)
	var disabled := face()
	disabled.modulate_color = Color("7a8ca6")
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_font_override("font", MenuSkin.DISPLAY)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color("fff8e8"))
	button.add_theme_color_override("font_disabled_color", Color("d1dbed"))
	button.add_theme_color_override("font_outline_color", Color("15315b"))
	button.add_theme_constant_override("outline_size", 3)

static func hero_texture(id: String) -> Texture2D:
	if id == "arcanist" and ResourceLoader.exists("res://assets/class-showcase/arcanist.png"):
		return load("res://assets/class-showcase/arcanist.png")
	if ResourceLoader.exists("res://assets/class-showcase/roster.png"):
		var regions := {"scavenger":Rect2(20,90,490,870),"engineer":Rect2(550,110,400,850),"warden":Rect2(1000,75,520,900)}
		var atlas := AtlasTexture.new()
		atlas.atlas = load("res://assets/class-showcase/roster.png")
		atlas.region = regions[id]
		atlas.filter_clip = true
		return atlas
	return Art.hero(id)

static func portrait_texture(id: String) -> Texture2D:
	var source := hero_texture(id)
	var atlas := AtlasTexture.new()
	if source is AtlasTexture:
		atlas.atlas = source.atlas
		var portraits := {"scavenger":Rect2(200,90,200,220),"engineer":Rect2(620,110,250,245),"warden":Rect2(1135,75,230,255)}
		atlas.region = portraits[id]
	else:
		atlas.atlas = source
		atlas.region = Rect2(350,75,360,360)
	atlas.filter_clip = true
	return atlas

static func caption(parent: Node, text: String, bounds: Rect2, size: int = 16, color: Color = Color.WHITE) -> Label:
	var label := MenuSkin.label(parent, text, size, color, true)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", MenuSkin.DISPLAY)
	label.add_theme_color_override("font_outline_color", Color("152b55"))
	label.add_theme_constant_override("outline_size", 3)
	label.position = bounds.position
	label.size = bounds.size
	return label

static func fixed_button(home: Control, parent: Control, text: String, bounds: Rect2, callback: Callable, gold: bool = false, font_size: int = 19) -> Button:
	var button: Button = home.button(text, callback, parent, int(bounds.size.y))
	button.position = bounds.position
	button.custom_minimum_size = bounds.size
	button.size = bounds.size
	action(button, gold, font_size)
	return button

static func show_page(home: Control) -> void:
	var id: String = home.inspected_class if not home.inspected_class.is_empty() else home.profile.data["class"]
	var info: Dictionary = Content.CLASSES[id]
	var available: bool = home.profile.class_unlocked(id)
	var selected: bool = home.profile.data["class"] == id
	var page := Control.new()
	page.name = "ClassShowcase"
	page.custom_minimum_size = Vector2(386,598)
	home.body.add_child(page)
	var hall_view := Control.new()
	hall_view.name = "ClassHall"
	hall_view.position = Vector2(0,30)
	hall_view.size = Vector2(386,345)
	hall_view.clip_contents = true
	hall_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(hall_view)
	var hall := Art.picture(hall_view, HALL, Rect2(0,-8,386,416))
	hall.stretch_mode = TextureRect.STRETCH_SCALE
	var hero := Portrait.new()
	hero.name = "ClassHero"
	hero.position = Vector2(58,35)
	hero.size = Vector2(270,309)
	page.add_child(hero)
	hero.configure(hero_texture(id), id, home.profile.data.settings.reduced_effects,preload("res://equipment_appearance.gd").from_profile(home.profile,id))
	var title := Art.picture(page, texture("ribbon"), Rect2(36,0,314,38))
	title.stretch_mode = TextureRect.STRETCH_SCALE
	caption(page,"Class",Rect2(66,0,254,35),25)
	var nameplate := Art.picture(page, texture("ribbon"), Rect2(63,344,260,36))
	nameplate.stretch_mode = TextureRect.STRETCH_SCALE
	caption(page,info.name,Rect2(91,344,204,34),23)
	var xp: int = home.profile.data.mastery[id]
	var level: int = Content.mastery_level(xp)
	var earned := xp - level * (level + 1) * 50
	var needed := (level + 1) * 100
	caption(page,"Mastery %d" % level,Rect2(90,381,206,24),16,Color("e9f2ff"))
	var progress := ProgressBar.new()
	progress.name = "ClassMasteryProgress"
	progress.max_value = needed
	progress.value = needed if level == 20 else earned
	MenuSkin.progress(progress)
	var fill: StyleBoxFlat = progress.get_theme_stylebox("fill").duplicate()
	fill.bg_color = Color("66c5ff")
	fill.set_content_margin_all(0)
	progress.add_theme_stylebox_override("fill",fill)
	var track: StyleBoxFlat = progress.get_theme_stylebox("background").duplicate()
	track.set_content_margin_all(0)
	progress.add_theme_stylebox_override("background",track)
	progress.position = Vector2(43,409)
	progress.size = Vector2(300,13)
	page.add_child(progress)
	caption(page,"%d / %d XP" % [earned,needed] if level < 20 else "Mastery complete",Rect2(93,405,200,21),12)
	for index in ORDER.size():
		var class_id: String = ORDER[index]
		var unlocked: bool = home.profile.class_unlocked(class_id)
		var slot := fixed_button(home,page,"",Rect2(10+index*94,431,84,76),func(): home.inspected_class=class_id; home.rebuild())
		slot.name = "PreviewClass_"+class_id
		for state in ["normal","hover","pressed","disabled"]:
			slot.add_theme_stylebox_override(state,StyleBoxEmpty.new())
		var backing := Art.picture(slot,texture("blue"),Rect2(2,2,80,61))
		backing.stretch_mode = TextureRect.STRETCH_SCALE
		var picture := Art.picture(slot,portrait_texture(class_id),Rect2(4,3,76,61))
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		picture.clip_contents = true
		var rim := Art.picture(slot,texture("portrait"),Rect2(0,0,84,66))
		rim.stretch_mode = TextureRect.STRETCH_SCALE
		rim.modulate = Color("ffdf83") if class_id == id else Color.WHITE
		caption(slot,Content.CLASSES[class_id].name,Rect2(0,61,84,16),12)
		slot.tooltip_text = Content.CLASSES[class_id].description+"\n"+Content.CLASSES[class_id].unlock
		if not unlocked:
			caption(slot,"Locked",Rect2(15,44,54,16),10,Color("e2e8f6"))
	var choose := fixed_button(home,page,"Selected" if selected else ("Select " + info.name if available else "Locked · " + info.unlock.replace(" (future content)","")),Rect2(43,513,300,32),func(): home.refresh(func(): return home.profile.select_class(id),info.name+" selected."),false,13)
	choose.name = "SelectClass"
	choose.custom_minimum_size.y = 32
	choose.size.y = 32
	choose.disabled = selected or not available or not home.profile.can_change_loadout()
	choose.tooltip_text = info.description+"\n"+info.unlock
	if selected or not available:
		choose.add_theme_stylebox_override("disabled",StyleBoxEmpty.new())
	else:
		choose.position.y = 507
		choose.custom_minimum_size.y = 44
		choose.size.y = 44
	var tree := fixed_button(home,page,"Talent Preview",Rect2(9,552,180,44),func(): home.page="talents"; home.tree_ability=""; home.rebuild(),false,17)
	tree.name = "OpenClassSkills"
	var training := fixed_button(home,page,"Training",Rect2(197,552,180,44),func(): home.navigate("combat_training"),true)
	training.name = "OpenCombatTraining"
	home.status_label.tooltip_text = "Permanent class unlocks add choices to future runs. Spell ranks reset each run."

static func decorate_navigation(home: Control) -> void:
	home.navigation.position.y = 684
	home.navigation.size.y = 72
	for index in home.navigation.get_child_count():
		var tab: Button = home.navigation.get_child(index)
		var active: bool = home.TABS[index][0] == home.active_tab()
		tab.custom_minimum_size.y = 72 if index == 2 else 64
		tab.size_flags_vertical = Control.SIZE_SHRINK_END
		action(tab,active,12)
		tab.add_theme_constant_override("icon_max_width",40)
