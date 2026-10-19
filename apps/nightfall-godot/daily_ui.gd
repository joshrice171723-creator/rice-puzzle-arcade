extends RefCounted
const Daily = preload("res://daily_progress.gd")
const KEY_ICON = preload("res://assets/menu-key.svg")

static func heading(home: Control, calendar_selected: bool) -> void:
	home.text_line("Daily rewards", 23, Color("ffd27c"))
	var tabs := HBoxContainer.new()
	home.body.add_child(tabs)
	var objectives: Button = home.button("Objectives", func(): home.navigate("daily"), tabs)
	objectives.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	objectives.disabled = not calendar_selected
	var supplies: Button = home.button("Supplies", func(): home.navigate("calendar"), tabs)
	supplies.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	supplies.disabled = calendar_selected
	var active: Button = supplies if calendar_selected else objectives
	active.add_theme_stylebox_override("disabled", home.style(Color("453d83"), Color("ffd27c")))
	active.add_theme_color_override("font_disabled_color", Color("ffe3a0"))

static func watch_day(home: Control, day: int) -> void:
	var refresh := Timer.new()
	refresh.wait_time = 30
	refresh.autostart = true
	home.body.add_child(refresh)
	refresh.timeout.connect(func():
		if home.page in ["daily", "calendar"] and home.profile.daily_state().day != day:
			home.rebuild())

static func show_calendar(home: Control) -> void:
	var state: Dictionary = home.profile.daily_state()
	heading(home, true)
	var claimed_today: bool = state.calendar_day >= state.day
	var next_claim: int = state.calendar_count % 7
	home.text_line("Seven-claim supplies", 17)
	home.text_line("Missed days keep your place. Refreshes at 00:00 UTC.", 12)
	var calendar := HBoxContainer.new()
	calendar.add_theme_constant_override("separation", 3)
	home.body.add_child(calendar)
	var shown_count := 7 if next_claim == 0 and state.calendar_count > 0 and claimed_today else next_claim
	for index in 7:
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var selected := index == next_claim and not claimed_today
		card.add_theme_stylebox_override("panel", home.style(Color("18346a"), Color("ffd27c") if selected else Color("47689e")))
		calendar.add_child(card)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 1)
		card.add_child(column)
		var day_label := Label.new()
		day_label.text = "✓" if index < shown_count else str(index + 1)
		day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		day_label.add_theme_font_size_override("font_size", 12)
		column.add_child(day_label)
		var kind: String = Daily.CALENDAR[index].keys()[0]
		var icon := TextureRect.new()
		icon.texture = KEY_ICON if kind == "cache_keys" else home.Art.item(kind)
		icon.name = "RewardIcon"
		icon.custom_minimum_size = Vector2(22, 22)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		column.add_child(icon)
		var amount := Label.new()
		amount.text = str(Daily.CALENDAR[index][kind])
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		amount.add_theme_font_size_override("font_size", 12)
		column.add_child(amount)
		card.tooltip_text = "Claim %d: %s" % [index + 1, Daily.reward_text(Daily.CALENDAR[index])]
	var calendar_label := "Supplies claimed today" if claimed_today else "Claim " + Daily.reward_text(Daily.CALENDAR[next_claim])
	var claim: Button = home.button(calendar_label, func():
		home.message = "Supplies saved." if home.profile.claim_calendar() else "Supplies could not be claimed."
		home.rebuild())
	claim.name = "CalendarClaim"
	claim.disabled = claimed_today or home.profile.blocked
	home.text_line("The calendar repeats after seven claims. Claim once per UTC day; no streak is lost when you take a break.", 14)
	home.button("Back to Expedition", func(): home.navigate("mission"))
	watch_day(home, state.day)

static func show_page(home: Control) -> void:
	var state: Dictionary = home.profile.daily_state()
	heading(home, false)
	home.text_line("Complete any 3 · %d/3" % mini(3, Daily.completed(state)), 17, Color("ffd27c"))
	home.text_line("Campaign or contracts. Clear or survive 60s; progress saves when the expedition ends.", 12)
	for objective in Daily.OBJECTIVES:
		var row := VBoxContainer.new()
		row.add_theme_constant_override("separation", 1)
		home.body.add_child(row)
		var label := Label.new()
		label.text = "%s  %d/%d" % [objective.label, state.progress[objective.id], objective.target]
		label.add_theme_font_size_override("font_size", 14)
		row.add_child(label)
		var bar := ProgressBar.new()
		bar.max_value = objective.target
		bar.value = state.progress[objective.id]
		bar.show_percentage = false
		bar.custom_minimum_size.y = 5
		var background: StyleBoxFlat = home.style(Color("0a1c3d"), Color("0a1c3d"))
		background.set_content_margin_all(0)
		bar.add_theme_stylebox_override("background", background)
		var fill: StyleBoxFlat = home.style(Color("bc8cf5"), Color("bc8cf5"))
		fill.set_content_margin_all(0)
		bar.add_theme_stylebox_override("fill", fill)
		row.add_child(bar)
	var ready := Daily.available_bonuses(state)
	home.text_line(Daily.reward_text(Daily.BONUS) + " per daily bonus", 12)
	var reward: Button = home.button("Claim bonus" + (" ×%d" % ready if ready > 1 else "") if ready > 0 else ("Daily bonus claimed" if state.claimed else "Complete 3 objectives"), func():
		home.message = "Daily rewards saved." if home.profile.claim_daily_bonus() else "Daily reward could not be claimed."
		home.rebuild())
	reward.name = "DailyBonusClaim"
	reward.disabled = ready <= 0 or home.profile.blocked
	home.text_line("Completed, unclaimed bonuses carry into the next day.", 12)
	home.button("Back to Expedition", func(): home.navigate("mission"))
	watch_day(home, state.day)
