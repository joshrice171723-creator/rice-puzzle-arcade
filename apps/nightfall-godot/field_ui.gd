extends RefCounted
const Cards = preload("res://reward_cards.gd")
const TRAIT_COPY = {"vitality":"+10% max HP per rank.\nHeal added HP.", "aim":"+6% weapon damage per rank.", "reach":"+25% XP pickup reach per rank."}
const DEFENSE_ICONS := {"barricade":"body", "turret":"weapon", "trap":"gems", "ward":"charm"}

static func label(arena: Node, text_value: String, size_value: int = 14) -> Label:
	var node := Label.new()
	node.text = text_value
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", size_value)
	arena.modal_body.add_child(node)
	return node

static func shrine(arena: Node) -> void:
	var field = arena.run.field
	var site: Dictionary = field.sites[field.active_site]
	arena.modal_title.text = site.name
	label(arena, "%d Field Scrap • this run only" % field.scrap, 16)
	if site.kind == "shop":
		label(arena, "Traits last for this expedition.")
		var choices := Cards.row(arena.modal_body)
		for id: String in field.TRAITS:
			var cost: int = field.trait_cost(id)
			Cards.add(choices, field.TRAITS[id].name, TRAIT_COPY[id], Cards.icon(id), "Rank %d/3" % field.traits[id], "%d scrap" % cost if cost >= 0 else "MAX", func(): arena.run.buy_trait(id), cost < 0 or field.scrap < cost)
	else:
		label(arena, "Choose one relic · %d/3 collected" % field.relics.size())
		var choices := Cards.row(arena.modal_body)
		for index in site.offers.size():
			var id: String = site.offers[index]
			Cards.add(choices, field.RELICS[id].name, field.RELICS[id].description, Cards.icon(id), "RELIC", "Take relic", func(): arena.run.choose_relic(index))
		var cost: int = field.reroll_cost()
		var button: Button = arena.make_button("Reroll • %d scrap" % cost if cost >= 0 else "Both rerolls used", func(): field.reroll(), arena.modal_body)
		button.disabled = cost < 0 or field.scrap < cost
	if not field.notice.is_empty():
		label(arena, field.notice, 13)
	arena.make_button("Leave shrine", func(): arena.run.leave_shrine(), arena.modal_body)

static func pack(arena: Node) -> void:
	var field = arena.run.field
	arena.modal_title.text = "Field Pack  •  %d/%d" % [field.bag.size(), field.capacity]
	label(arena, "Protected %d/%d. Victory banks everything. On defeat, only protected loot returns with you." % [field.secured_count(), field.secure_capacity])
	var pages := maxi(1, ceili(field.bag.size() / 4.0))
	arena.pack_page = clampi(arena.pack_page, 0, pages - 1)
	if field.bag.is_empty():
		label(arena, "Find supply caches around the courtyard. Stay inside their ring to open them.")
	for index in range(arena.pack_page * 4, mini(field.bag.size(), (arena.pack_page + 1) * 4)):
		var item: Dictionary = field.bag[index]
		label(arena, "%s%s  ×%d" % ["◆ " if item.secure else "", item.name, item.amount], 15)
		var row := HBoxContainer.new()
		arena.modal_body.add_child(row)
		var protect: Button = arena.make_button("Unprotect" if item.secure else "Protect", func(): field.set_secure(item.id, not item.secure), row, 40)
		protect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		protect.disabled = not item.secure and field.secured_count() >= field.secure_capacity
		var discard: Button = arena.make_button("Discard", func(): arena.pending_discard = item.id; arena.last_screen = "", row, 40)
		discard.disabled = item.secure
	if arena.pending_discard >= 0:
		label(arena, "Discard this unprotected item permanently?")
		var row := HBoxContainer.new()
		arena.modal_body.add_child(row)
		arena.make_button("Discard item", func(): field.discard(arena.pending_discard); arena.pending_discard = -1; arena.last_screen = "", row, 40)
		arena.make_button("Keep it", func(): arena.pending_discard = -1; arena.last_screen = "", row, 40)
	if pages > 1:
		arena.make_button("Next page • %d/%d" % [arena.pack_page + 1, pages], func(): arena.pack_page = (arena.pack_page + 1) % pages; arena.last_screen = "", arena.modal_body, 40)
	arena.make_button("Back to the field", func(): arena.pending_discard = -1; arena.run.close_pack(), arena.modal_body)

static func build(arena: Node) -> void:
	var run = arena.run
	arena.modal_title.text = "Field Workshop"
	var summary := PanelContainer.new()
	var summary_face := Cards.MenuSkin.surface("inset")
	summary_face.set_content_margin_all(10)
	summary.add_theme_stylebox_override("panel", summary_face)
	arena.modal_body.add_child(summary)
	var summary_row := HBoxContainer.new()
	summary_row.add_theme_constant_override("separation", 10)
	summary.add_child(summary_row)
	Cards.MenuSkin.icon(summary_row, Cards.icon("parts"), Vector2(32,32))
	var workshop_note := Cards.MenuSkin.label(summary_row, "%d scrap\nFIELD MATERIAL" % run.field.scrap, 14, Color("ffe1a1"))
	workshop_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	Cards.MenuSkin.label(summary_row, "CAPACITY\n%d / %d" % [run.defenses.used_capacity(), run.Defenses.CAPACITY], 14, Color("bde4ff"), true)
	label(arena, "Place a defense at your feet. It holds this courtyard until it is destroyed.", 13)
	var choices := Cards.row(arena.modal_body)
	for id: String in run.blueprints:
		var info: Dictionary = run.Defenses.TYPES[id]
		var cost: int = run.build_cost(id)
		var capacity_text := "Uses %d capacity" % info.capacity
		var description := "%s\n%s" % [info.description, capacity_text]
		Cards.add(choices, info.name, description, Cards.icon(DEFENSE_ICONS.get(id, "parts")), "FIELD DEFENSE", "%d scrap" % cost, func(): run.place_structure(id), run.field.scrap < cost or run.defenses.used_capacity() + info.capacity > run.Defenses.CAPACITY)
	if not run.defenses.notice.is_empty():
		var notice := label(arena, run.defenses.notice, 13)
		notice.add_theme_color_override("font_color", Color("ffd5a3"))
	if run.class_id == "engineer" and run.mastery_level >= 15:
		var dismantle: Button = arena.make_button("Reclaim nearest  •  40% scrap back", func(): run.dismantle_structure(), arena.modal_body, 44)
		dismantle.disabled = run.defenses.nearest_structure(run.player, 150).is_empty()
	arena.make_button("Back to the field", func(): run.close_build(), arena.modal_body, 44)
