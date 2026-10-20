extends SceneTree

var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	var arena = load("res://main.tscn").instantiate()
	arena.testing = true
	root.add_child(arena)
	arena.home.hide()
	arena.run.configure(1, arena.profile.stats())
	arena.run.field.scrap = 500
	arena.run.open_build()
	arena.update_modal()
	await process_frame
	check(arena.modal_title.text == "Field Workshop", "Build mode has a workshop identity")
	var choices = arena.modal_body.find_child("RewardChoices", true, false)
	check(choices != null, "Workshop presents defense choices as illustrated cards")
	check(choices.get_child_count() == arena.run.blueprints.size(), "Workshop includes every owned defense blueprint")
	for card in choices.get_children():
		check(card.get_meta("reward_card", false), "Defense choice uses the shared illustrated card treatment")
		var actions: Array[Node] = card.find_children("*", "Button", true, false)
		check(actions.size() == 1 and actions[0].get_meta("reward_card_action", false), "Defense card provides a placement action")
	check(arena.modal_body.get_child_count() >= arena.run.blueprints.size() + 3, "Workshop retains materials, capacity, choices and return action")
	arena.queue_free()
	await process_frame
	print("Field workshop UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
