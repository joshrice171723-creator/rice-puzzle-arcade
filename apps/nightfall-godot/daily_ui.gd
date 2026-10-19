extends RefCounted
const Daily = preload("res://daily_progress.gd")
const KEY_ICON = preload("res://assets/menu-key.svg")
const UI = preload("res://preparation_ui.gd")

static func heading(home: Control, calendar_selected: bool) -> void:
	UI.title(home, "Daily Rewards", "quartermaster")
	var tabs := HBoxContainer.new()
	tabs.custom_minimum_size.x = 300
	tabs.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tabs.add_theme_constant_override("separation", 8)
	home.body.add_child(tabs)
	var objectives: Button = home.button("Objectives", func(): home.navigate("daily"), tabs, 48)
	objectives.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objectives.disabled = not calendar_selected
	var supplies: Button = home.button("Supplies", func(): home.navigate("calendar"), tabs, 48)
	supplies.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	supplies.disabled = calendar_selected
	var active: Button = supplies if calendar_selected else objectives
	active.add_theme_stylebox_override("disabled", home.MenuSkin.surface("gold"))
	active.add_theme_color_override("font_disabled_color", Color("ffe5a7"))

static func watch_day(home: Control, day: int) -> void:
	var refresh := Timer.new()
	refresh.wait_time = 30
	refresh.autostart = true
	home.body.add_child(refresh)
	refresh.timeout.connect(func():
		if home.page in ["daily", "calendar"] and home.profile.daily_state().day != day:
			home.rebuild())

static func reward_icons(home: Control, parent: Node, rewards: Dictionary, large: bool = false) -> void:
	for kind: String in rewards:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 3)
		parent.add_child(row)
		var picture := UI.art(home, row, KEY_ICON if kind == "cache_keys" else home.Art.item(kind), Vector2(30, 30) if large else Vector2(23, 23))
		picture.name = "RewardIcon"
		UI.label_in(home, row, str(rewards[kind]), 19 if large else 15, Color("fff0ca")).vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.tooltip_text = Daily.reward_text({kind: rewards[kind]})

static func show_calendar(home: Control) -> void:
	var state: Dictionary = home.profile.daily_state()
	heading(home, true)
	var claimed_today: bool = state.calendar_day >= state.day
	var next_claim: int = state.calendar_count % 7
	var shown_count := 7 if next_claim == 0 and state.calendar_count > 0 and claimed_today else next_claim
	var calendar := GridContainer.new()
	calendar.columns = 3
	calendar.add_theme_constant_override("h_separation", 7)
	calendar.add_theme_constant_override("v_separation", 7)
	home.body.add_child(calendar)
	for index in 6:
		calendar_card(home, calendar, index, index < shown_count, index == next_claim and not claimed_today)
	var finale := UI.card(home, home.body, Color("ce9f4b") if next_claim == 6 and not claimed_today else Color("7260ad"), 8)
	var final_row := HBoxContainer.new()
	finale.add_child(final_row)
	UI.art(home, final_row, home.Art.icon("quartermaster"), Vector2(46, 46))
	var final_words := VBoxContainer.new()
	final_words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	final_row.add_child(final_words)
	UI.label_in(home, final_words, "Claim 7 · Supply Cache", 18, Color("ffdb99"))
	UI.label_in(home, final_words, "Collected" if shown_count == 7 else ("Ready today" if next_claim == 6 and not claimed_today else "Finish this supply cycle"), 12, Color("c7b7eb"))
	reward_icons(home, final_row, Daily.CALENDAR[6], true)
	var calendar_label := "Supplies claimed today" if claimed_today else "Claim " + Daily.reward_text(Daily.CALENDAR[next_claim])
	var claim: Button = home.button(calendar_label, func():
		home.message = "Supplies saved." if home.profile.claim_calendar() else "Supplies could not be claimed."
		home.rebuild())
	claim.name = "CalendarClaim"
	claim.disabled = claimed_today or home.profile.blocked
	home.MenuSkin.action(claim, "gold")
	home.text_line("Missing a day keeps your place. One claim per UTC day.\nRefresh: 00:00 UTC · repeats after seven claims.", 12)
	home.button("Back to Expedition", func(): home.navigate("mission"), null, 38)
	watch_day(home, state.day)

static func calendar_card(home: Control, parent: Node, index: int, collected: bool, selected: bool) -> void:
	var card := UI.card(home, parent, Color("d1a358") if selected else Color("4e5f9b"), 4)
	card.get_parent().custom_minimum_size.y = 76
	card.add_theme_constant_override("separation", 2)
	card.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var heading_label := UI.label_in(home, card, "✓ CLAIMED" if collected else "CLAIM %d" % (index + 1), 11, Color("ffdb9a") if selected else Color("c6d5f6"))
	heading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var kind: String = Daily.CALENDAR[index].keys()[0]
	var picture := UI.art(home, card, KEY_ICON if kind == "cache_keys" else home.Art.item(kind), Vector2(0, 28))
	picture.name = "RewardIcon"
	picture.modulate = Color("98a3c0") if collected else Color.WHITE
	UI.label_in(home, card, str(Daily.CALENDAR[index][kind]), 19, Color("fff0ca")).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.get_parent().tooltip_text = "Claim %d: %s" % [index + 1, Daily.reward_text(Daily.CALENDAR[index])]

static func show_page(home: Control) -> void:
	var state: Dictionary = home.profile.daily_state()
	heading(home, false)
	var progress := HBoxContainer.new()
	home.body.add_child(progress)
	UI.label_in(home, progress, "Complete any 3", 18, Color("ffdf9e")).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UI.label_in(home, progress, "%d / 3" % mini(3, Daily.completed(state)), 18, Color("f2e9ff"))
	var objectives := UI.card(home, home.body, Color("3a629c"), 12)
	objectives.add_theme_constant_override("separation", 9)
	for index in Daily.OBJECTIVES.size():
		var objective: Dictionary = Daily.OBJECTIVES[index]
		var completed: bool = state.progress[objective.id] >= objective.target
		var entry := VBoxContainer.new()
		objectives.add_child(entry)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		entry.add_child(row)
		UI.art(home, row, home.Art.icon(["training", "quartermaster", "mission", "class"][index]), Vector2(37, 37))
		var words := VBoxContainer.new()
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		words.add_theme_constant_override("separation", 2)
		row.add_child(words)
		var top := HBoxContainer.new()
		words.add_child(top)
		UI.label_in(home, top, objective.label, 14).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UI.label_in(home, top, "✓" if completed else "%d/%d" % [state.progress[objective.id], objective.target], 14, Color("ffdb99") if completed else Color("cbb8f4"))
		UI.rail(home, words, state.progress[objective.id], objective.target, 6)
	var reward_card := UI.card(home, home.body, Color("9871c2"), 7)
	var bundle := HBoxContainer.new()
	reward_card.add_child(bundle)
	UI.label_in(home, bundle, "DAILY BONUS", 12, Color("c9b0f2")).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_icons(home, bundle, Daily.BONUS)
	var ready := Daily.available_bonuses(state)
	var reward: Button = home.button("Claim bonus" + (" ×%d" % ready if ready > 1 else "") if ready > 0 else ("Daily bonus claimed" if state.claimed else "Complete 3 objectives"), func():
		home.message = "Daily rewards saved." if home.profile.claim_daily_bonus() else "Daily reward could not be claimed."
		home.rebuild())
	reward.name = "DailyBonusClaim"
	reward.disabled = ready <= 0 or home.profile.blocked
	home.MenuSkin.action(reward, "gold")
	home.text_line("Campaign or contracts: clear or survive 60s. Progress saves at run end. Unclaimed bonuses carry forward.", 12)
	home.button("Back to Expedition", func(): home.navigate("mission"), null, 36)
	watch_day(home, state.day)
