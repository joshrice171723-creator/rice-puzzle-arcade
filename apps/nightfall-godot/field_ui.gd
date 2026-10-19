extends RefCounted

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
		label(arena, "Buy traits for this attempt. You can buy several before leaving.")
		for id: String in field.TRAITS:
			var cost: int = field.trait_cost(id)
			var title: String = "%s %d/3 • %s" % [field.TRAITS[id].name, field.traits[id], "%d scrap" % cost if cost >= 0 else "MAX"]
			var button: Button = arena.make_button(title, func(): arena.run.buy_trait(id), arena.modal_body)
			button.disabled = cost < 0 or field.scrap < cost
			label(arena, field.TRAITS[id].description, 13)
	else:
		label(arena, "Choose one relic. %d of 3 collected this run." % field.relics.size())
		for index in site.offers.size():
			var id: String = site.offers[index]
			arena.make_button(field.RELICS[id].name, func(): arena.run.choose_relic(index), arena.modal_body)
			label(arena, field.RELICS[id].description)
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
	arena.modal_title.text = "Field Defenses"
	label(arena, "%d scrap • capacity %d/%d" % [run.field.scrap, run.defenses.used_capacity(), run.Defenses.CAPACITY], 16)
	for id: String in run.blueprints:
		var info: Dictionary = run.Defenses.TYPES[id]
		var cost: int = run.build_cost(id)
		var button: Button = arena.make_button("%s • %d scrap" % [info.name, cost], func(): run.place_structure(id), arena.modal_body)
		button.disabled = run.field.scrap < cost or run.defenses.used_capacity() + info.capacity > run.Defenses.CAPACITY
		label(arena, info.description, 13)
	label(arena, run.defenses.notice, 13)
	arena.make_button("Back to the field", func(): run.close_build(), arena.modal_body)
