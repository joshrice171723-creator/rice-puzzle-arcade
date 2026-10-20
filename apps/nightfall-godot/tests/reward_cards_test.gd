extends SceneTree
var checks := 0
var failures := 0
var capture_dir := ""

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
	call_deferred("verify")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func settle() -> void:
	for n in 8:
		await process_frame

func marked(node: Node, key: String) -> Array[Node]:
	var found: Array[Node] = []
	if node.has_meta(key):
		found.append(node)
	for child in node.get_children():
		found.append_array(marked(child,key))
	return found

func screenshot(name: String) -> void:
	if capture_dir.is_empty():
		return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(capture_dir.path_join(name + ".png")) == OK,"Capture saved")

func verify() -> void:
	var arena = load("res://main.tscn").instantiate()
	arena.testing = true
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.home.hide()
	arena.run.configure(1,arena.profile.stats())
	arena.run.paused = false
	var field = arena.run.field
	for dimensions in [Vector2i(430,760),Vector2i(320,568)]:
		root.size = dimensions
		for site in [0,1]:
			field.active_site = site
			field.notice = ""
			field.scrap = 60
			field.sites[1].offers.assign(["emberleaf","obsidian"])
			arena.run.phase = "shrine"
			arena.last_screen = ""
			arena.update_modal()
			await settle()
			check(root.get_visible_rect().encloses(arena.modal.get_global_rect()),"Shrine cards fit " + str(dimensions))
			var cards := marked(arena.modal_body,"reward_card")
			check(cards.size() == (3 if site == 0 else 2),"Shop has three cards and relic shrine has two")
			for card in cards:
				var picture = card.find_child("RewardArtwork",true,false)
				check(picture != null and picture.texture != null and picture.size.y >= 70,"Each card has substantial reward artwork")
				check(arena.modal.get_global_rect().encloses(card.get_global_rect()),"Card stays inside its popup")
			await screenshot(("traits" if site == 0 else "relics") + "-" + str(dimensions.x))
			if site == 0:
				var buttons := marked(arena.modal_body,"reward_card_action")
				var rank_before: int = field.traits.vitality
				buttons[0].pressed.emit()
				check(field.traits.vitality == rank_before + 1 and field.scrap == 60 - field.TRAIT_COSTS[rank_before],"Card buys the correct trait at authoritative cost")
				field.traits.vitality = 0
			else:
				var buttons := marked(arena.modal_body,"reward_card_action")
				buttons[1].pressed.emit()
				check("obsidian" in field.relics and field.active_site == -1 and arena.run.phase == "waves","Card selects exactly the intended relic and resumes")
				field.relics.clear()
		field.active_site = 0
		field.scrap = 0
		arena.run.phase = "shrine"
		arena.last_screen = ""
		arena.update_modal()
		await settle()
		check(marked(arena.modal_body,"reward_card_action").all(func(b): return b.disabled),"Unaffordable traits stay disabled")
		arena.run.phase = "upgrade"
		arena.run.spells.clear()
		arena.run.level = 2
		arena.run.offers.assign([arena.run.spell_offer("ember"),arena.run.spell_offer("frost"),arena.run.spell_offer("chain")])
		arena.last_screen = ""
		arena.update_modal()
		await settle()
		check(marked(arena.modal_body,"reward_card").size() == 3,"Level-up uses three illustrated cards")
		check(root.get_visible_rect().encloses(arena.modal.get_global_rect()),"Level-up cards fit phone")
		await screenshot("powers-" + str(dimensions.x))
		arena.run.spells.clear()
		marked(arena.modal_body,"reward_card_action")[0].pressed.emit()
		check(arena.run.spells.has("ember") and arena.run.phase == "waves","Card learns the selected automatic attack")
		for group in [["wisp","ground","gravity"],["ember","frost","chain"],["rounds","mechanic","pierce"]]:
			arena.run.phase = "upgrade"
			arena.run.spells.clear()
			arena.run.passives = {"focus":1,"vital":1,"mechanic":1,"magnet":1,"channel":1}
			arena.run.offers.clear()
			for id in group:
				if arena.run.Content.SPELLS.has(id):
					arena.run.offers.append(arena.run.spell_offer(id,3))
				else:
					var info: Dictionary=arena.run.Content.PASSIVES[id]
					arena.run.offers.append({"id":id,"name":info.name+" • Rank 1/3","description":info.description})
			arena.last_screen = ""
			arena.update_modal()
			await settle()
			check(root.get_visible_rect().encloses(arena.modal.get_global_rect()),"Long evolved/passive choices fit phone")
			for card in marked(arena.modal_body,"reward_card"):
				var description: Label=card.find_child("RewardDescription",true,false)
				check(description!=null and card.get_global_rect().encloses(description.get_global_rect()),"Full description is visible without inner scrolling")
			if group[0]=="wisp":await screenshot("evolved-powers-"+str(dimensions.x))
		arena.run.passives.clear()
	field.active_site = -1
	arena.run.player = Vector2(600,500)
	arena.run.phase = "waves"
	arena.last_screen = ""
	arena.update_modal()
	await settle()
	await screenshot("shrine-scale")
	print("Reward cards: %d checks, %d failures" % [checks,failures])
	arena.queue_free()
	await process_frame
	quit(1 if failures else 0)
