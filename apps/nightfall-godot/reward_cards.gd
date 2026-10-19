extends RefCounted
## Illustrated choices; callbacks still use the authoritative Run/Field actions.
const MenuSkin = preload("res://menu_skin.gd")
const Art = preload("res://haven_art.gd")
const Powers = preload("res://power_hud.gd")
const REWARDS = preload("res://assets/shrine-cards/rewards.png")
const REWARD_ORDER = ["emberleaf", "obsidian", "feather", "lantern", "moonstone", "cinder", "vitality", "aim", "reach"]

static func row(parent: Node) -> HBoxContainer:
	var result := HBoxContainer.new()
	result.add_theme_constant_override("separation", 7)
	parent.add_child(result)
	return result

static func icon(id: String) -> Texture2D:
	if id in Powers.ORDER:
		return Powers.texture_for(id)
	var reward_id: String = {"vital":"vitality", "heal":"vitality", "magnet":"reach", "pierce":"aim", "focus":"cinder", "channel":"moonstone"}.get(id, id)
	var index := REWARD_ORDER.find(reward_id)
	if index >= 0:
		var texture := AtlasTexture.new()
		texture.atlas = REWARDS
		texture.region = Rect2((index % 3) * 418, (index / 3) * 418, 418, 418)
		texture.filter_clip = true
		return texture
	var aliases := {"rounds":"weapon", "quick":"gadget", "focus":"gems", "vital":"hp", "fleet":"boots", "mechanic":"parts", "magnet":"gadget", "pierce":"weapon", "channel":"charm", "heal":"hp", "vitality":"hp", "aim":"weapon", "reach":"gadget", "emberleaf":"hp", "obsidian":"body", "feather":"boots", "lantern":"charm", "moonstone":"gems", "cinder":"ring"}
	return Art.item(aliases.get(id, "parts"))

static func add(parent: Node, title: String, description: String, image: Texture2D, badge: String, action: String, callback: Callable, disabled: bool = false) -> Button:
	var body := MenuSkin.panel(parent, "inset", 8)
	var shell: PanelContainer = body.get_parent()
	shell.set_meta("reward_card", true)
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var face := MenuSkin.surface("inset")
	face.set_content_margin_all(8)
	shell.add_theme_stylebox_override("panel",face)
	var name_label := MenuSkin.label(body, title, 16, Color("fff3cf"), true)
	name_label.add_theme_font_override("font", MenuSkin.DISPLAY)
	name_label.custom_minimum_size.y = 40
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var picture := MenuSkin.icon(body, image, Vector2(0,92))
	picture.name = "RewardArtwork"
	var tag := MenuSkin.label(body, badge, 12, Color("c5b8ff"), true)
	tag.custom_minimum_size.y = 30
	tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0,114)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var detail := MenuSkin.label(scroll, description, 13, Color("e1edff"), true)
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var select := Button.new()
	select.text = action
	if action.ends_with(" scrap"):
		select.text = action.trim_suffix(" scrap")
		select.icon = Art.item("parts")
		select.expand_icon = true
		select.add_theme_constant_override("icon_max_width",16)
	select.tooltip_text = title + "\n" + description
	select.custom_minimum_size.y = 40
	select.disabled = disabled
	select.set_meta("reward_card_action", true)
	MenuSkin.action(select,"gold" if not disabled else "disabled")
	select.add_theme_font_size_override("font_size", 14)
	select.pressed.connect(callback)
	body.add_child(select)
	return select

static func upgrades(arena: Node) -> void:
	var choices := row(arena.modal_body)
	for index in arena.run.offers.size():
		var offer: Dictionary = arena.run.offers[index]
		var parts := str(offer.name).split("•", true, 1)
		var badge := parts[1].strip_edges() if parts.size() > 1 else "NEW POWER"
		add(choices,parts[0].strip_edges(),offer.description,icon(offer.id),badge,"Choose",func(): arena.run.choose_offer(index))
