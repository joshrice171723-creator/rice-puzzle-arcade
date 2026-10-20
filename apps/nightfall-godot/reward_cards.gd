extends RefCounted
## Illustrated choices; callbacks still use the authoritative Run/Field actions.
const MenuSkin = preload("res://menu_skin.gd")
const Art = preload("res://haven_art.gd")
const Powers = preload("res://power_hud.gd")
const REWARDS = preload("res://assets/shrine-cards/rewards.png")
const REWARD_ORDER = ["emberleaf", "obsidian", "feather", "lantern", "moonstone", "cinder", "vitality", "aim", "reach"]

static func row(parent: Node) -> VBoxContainer:
	var result := VBoxContainer.new()
	result.name = "RewardChoices"
	result.add_theme_constant_override("separation", 9)
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
	var shell := PanelContainer.new()
	shell.set_meta("reward_card", true)
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var accent := Color("b88cff") if badge == "RELIC" else Color("79cfff")
	if badge.contains("Evol"):
		accent = Color("f7c96f")
	var face := MenuSkin.surface("inset")
	face.set_content_margin_all(10)
	shell.add_theme_stylebox_override("panel", face)
	parent.add_child(shell)
	var layout := HBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	shell.add_child(layout)
	var artwork := VBoxContainer.new()
	artwork.custom_minimum_size.x = 88
	artwork.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	artwork.add_theme_constant_override("separation", 4)
	layout.add_child(artwork)
	var frame := PanelContainer.new()
	var rim := StyleBoxFlat.new()
	rim.bg_color = Color("101d44")
	rim.border_color = accent
	rim.set_border_width_all(2)
	rim.set_corner_radius_all(9)
	rim.set_content_margin_all(4)
	frame.add_theme_stylebox_override("panel", rim)
	artwork.add_child(frame)
	var picture := MenuSkin.icon(frame, image, Vector2(80,80))
	picture.name = "RewardArtwork"
	var tag := MenuSkin.label(artwork, badge, 11, accent, true)
	tag.name = "RewardRank"
	tag.autowrap_mode = TextServer.AUTOWRAP_OFF
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 5)
	layout.add_child(body)
	var name_label := MenuSkin.label(body, title, 19, Color("fff1c9"))
	name_label.name = "RewardName"
	name_label.add_theme_font_override("font", MenuSkin.DISPLAY)
	var detail := MenuSkin.label(body, description, 13, Color("e1edff"))
	detail.name = "RewardDescription"
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var select := Button.new()
	select.text = action
	if action.ends_with(" scrap"):
		select.text = action.trim_suffix(" scrap")
		select.icon = Art.item("parts")
		select.expand_icon = true
		select.add_theme_constant_override("icon_max_width", 21)
	select.tooltip_text = title + "\n" + description
	select.custom_minimum_size = Vector2(108,44)
	select.size_flags_horizontal = Control.SIZE_SHRINK_END
	select.disabled = disabled
	select.set_meta("reward_card_action", true)
	MenuSkin.action(select, "gold" if not disabled else "disabled")
	select.add_theme_font_size_override("font_size", 16)
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
