extends RefCounted
## Painted, contained service pages. Profile methods remain the transaction boundary.
const MenuSkin = preload("res://menu_skin.gd")
const Art = preload("res://haven_art.gd")
const Content = preload("res://haven_content.gd")
const UI = preload("res://preparation_ui.gd")
const KEY = preload("res://assets/menu-key.svg")

static func heading(home: Control, words: String, _image: Texture2D) -> void:
	UI.title(home, words)
	home.body.get_child(home.body.get_child_count()-1).tooltip_text = words

static func content(home: Control, name_value: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = name_value
	scroll.custom_minimum_size.y = 80
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	home.body.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	scroll.add_child(column)
	return column

static func action(home: Control, words: String, callback: Callable, parent: Node, kind: String = "blue", height: int = 44) -> Button:
	var node: Button = home.button(words, callback, parent, height)
	node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER if parent == home.body else Control.SIZE_EXPAND_FILL
	MenuSkin.action(node, kind)
	return node

static func back(home: Control, destination: String = "haven", words: String = "Back to Base") -> void:
	action(home, words, func(): home.navigate(destination), home.body, "blue", 40)

static func fact(parent: Node, icon: Texture2D, label_value: String, detail: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	MenuSkin.icon(row, icon, Vector2(34,34))
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 1)
	row.add_child(words)
	MenuSkin.label(words, label_value, 16, Color("ffe2a0"))
	MenuSkin.label(words, detail, 13)

static func facility(home: Control) -> void:
	var id: String = home.facility
	var definition: Dictionary = Content.FACILITIES[id]
	var rank: int = home.profile.data.facilities[id]
	var complete := rank >= 2
	heading(home, definition.name, Art.icon(id))
	var column := content(home, "FacilityScroll")
	var stage := MenuSkin.panel(column, "panel", 8)
	var portrait := MenuSkin.icon(stage, Art.icon(id), Vector2(0,130))
	portrait.name = "FacilityPortrait"
	MenuSkin.label(stage, "Rank %d / 2" % rank, 21, Color("ffe2a0"), true)
	var comparison := MenuSkin.panel(column, "panel", 14)
	var labels := HBoxContainer.new()
	comparison.add_child(labels)
	MenuSkin.label(labels, "CURRENT", 12, Color("b7c9e9")).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MenuSkin.label(labels, "COMPLETE" if complete else "NEXT RANK", 12, Color("ffe2a0"))
	var before: String
	var after: String
	var note: String
	if id == "workshop":
		before = "100% credit cost"
		after = "90% credit cost"
		note = "Equipment level upgrades cost 10% fewer credits. Parts costs stay the same."
	elif id == "infirmary":
		before = "20% HP restored"
		after = "25% HP restored"
		note = "Your Field Medkit restores more maximum HP. One use per run."
	else:
		before = "8 backpack slots"
		after = "9 backpack slots"
		note = "Carry one more loot item. Your two secure stash slots stay protected."
	var values := HBoxContainer.new()
	comparison.add_child(values)
	MenuSkin.label(values, after if complete else before, 16).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	MenuSkin.label(values, "✓" if complete else "→ " + after, 16, Color("ffe2a0"))
	MenuSkin.label(comparison, note, 13)
	if not complete:
		MenuSkin.label(comparison, "UPGRADE COST", 12, Color("b7c9e9"))
		MenuSkin.cost_row(comparison, home.profile, {"credits":definition.credits, "parts":definition.parts})
	if not home.profile.can_change_loadout():
		MenuSkin.label(column, "Finish your saved expedition to upgrade your base.", 13, Color("e1c3ff"))
	var improve := action(home, "Rank complete" if complete else "Upgrade to Rank 2", func():
		home.refresh(func(): return home.profile.upgrade_facility(id), definition.name + " improved."), home.body, "gold", 46)
	improve.disabled = complete or not home.profile.can_change_loadout() or home.profile.data.credits < definition.credits or home.profile.data.parts < definition.parts
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 6)
	home.body.add_child(footer)
	if id == "workshop":
		action(home, "Equipment", func(): home.navigate("gear"), footer)
		action(home, "Craft", func(): home.navigate("craft"), footer)
	elif id == "quartermaster":
		action(home, "Find materials", func(): home.navigate("contracts"), footer)
	action(home, "Back to Base", func(): home.navigate("haven"), footer)

static func contracts(home: Control) -> void:
	heading(home, "Salvage Contracts", Art.icon("mission"))
	var column := content(home, "ContractsScroll")
	MenuSkin.label(column, "Scavenge · Collect · Extract", 16, Color("ffe2a0"), true)
	var route := MenuSkin.panel(column, "panel", 14)
	fact(route, KEY, "01 · Open 3 caches", "Scavenge supplies while holding off the undead.")
	fact(route, Art.icon("haven"), "02 · Reach the beacon", "Powers up at 90 seconds. Hold its central ring for 3 seconds.")
	fact(route, Art.icon("mission"), "03 · Extract", "Leave before the 3-minute deadline. No boss in this side mode.")
	var reward := MenuSkin.panel(column, "panel", 9)
	var choose: Button = action(home, Content.SLOT_LABELS[home.contract_slot] + "  ›", func():
		home.contract_slot = Content.SLOTS[(Content.SLOTS.find(home.contract_slot) + 1) % Content.SLOTS.size()]
		home.rebuild(), reward, "violet", 44)
	choose.icon = home.item_texture(home.contract_slot)
	choose.expand_icon = true
	choose.add_theme_constant_override("icon_max_width", 35)
	choose.tooltip_text = "Tap to change the guaranteed equipment slot"
	var loot := HBoxContainer.new()
	loot.add_theme_constant_override("separation", 8)
	reward.add_child(loot)
	for currency in [["credits",80],["parts",2]]:
		MenuSkin.icon(loot, Art.item(currency[0]), Vector2(25,27))
		MenuSkin.label(loot, "+%d" % currency[1], 16, Color("ffe2a0"))
	MenuSkin.label(reward, "45 Survivor XP · 25 Mastery XP", 13, Color("e1c3ff"))
	MenuSkin.label(reward, "75% Common / 25% Uncommon · Collected loot is extra.", 12)
	var progress := ProgressBar.new()
	progress.custom_minimum_size.y = 10
	progress.max_value = 3
	progress.value = int(home.profile.data.contract_clears) % 3
	MenuSkin.progress(progress)
	reward.add_child(progress)
	MenuSkin.label(reward, "%d / 3 clears · Next bonus: 1 supply key" % (int(home.profile.data.contract_clears) % 3), 12, Color("ffe2a0"))
	var unlocked: bool = home.profile.Salvage.unlocked(home.profile)
	if not home.profile.data.active_attempt.is_empty():
		MenuSkin.label(column, "Resume or finish your saved expedition first.", 13, Color("e1c3ff"))
	var start := action(home, "Start contract" if unlocked else "Clear Garage Lights first", func(): home.contract_requested.emit(home.contract_slot), home.body, "gold", 48)
	start.disabled = not unlocked or not home.profile.can_change_loadout()
	back(home)

static func settings(home: Control) -> void:
	heading(home, "Settings", Art.item("parts"))
	var column := content(home, "SettingsScroll")
	var audio := MenuSkin.panel(column, "panel", 10)
	MenuSkin.label(audio, "Sound & music", 21, Color("ffe2a0"))
	for key in ["music", "sound"]:
		MenuSkin.label(audio, "%s  ·  %.0f%%" % ["Music" if key == "music" else "Sound effects", float(home.profile.data.settings[key]) * 100.0], 16)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 5)
		audio.add_child(row)
		for level in [0.0, 0.25, 0.5, 1.0]:
			var selected := is_equal_approx(float(home.profile.data.settings[key]), level)
			var button := action(home, "Off" if level == 0.0 else "%.0f%%" % (level*100.0), func():
				home.refresh(func(): return home.profile.set_setting(key, level), "Audio preference saved."), row, "gold" if selected else "blue", 40)
			button.add_theme_font_size_override("font_size", 16)
			button.name = key + str(roundi(level*100))
	var preferences := MenuSkin.panel(column, "panel", 10)
	MenuSkin.label(preferences, "Comfort", 21, Color("ffe2a0"))
	for entry in [["haptics","Vibration"],["reduced_effects","Reduced effects"]]:
		var key: String = entry[0]
		var enabled: bool = home.profile.data.settings[key]
		var row := HBoxContainer.new()
		preferences.add_child(row)
		var label := MenuSkin.label(row, entry[1], 16)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var toggle := action(home, "On" if enabled else "Off", func(): home.refresh(func(): return home.profile.set_setting(key, not enabled), "Preference saved."), row, "violet" if enabled else "blue", 40)
		toggle.size_flags_horizontal = Control.SIZE_SHRINK_END
		toggle.custom_minimum_size.x = 80
		if key == "reduced_effects":
			MenuSkin.label(preferences, "Fewer flashes and softer spell effects. Attack warnings stay visible.", 12)
	var privacy := MenuSkin.panel(column, "panel", 14)
	MenuSkin.label(privacy, "Privacy & diagnostics", 18, Color("e1c3ff"))
	MenuSkin.label(privacy, "Review ad privacy options and internal test tools.", 13)
	action(home, "Open privacy & test tools", func(): home.diagnostics_requested.emit(), privacy, "blue", 42)
	MenuSkin.label(column, "Preferences are saved on this device.", 12, Color("b7c9e9"), true)
	back(home)

static func zones(home: Control) -> void:
	heading(home, "Expedition Zones", Art.icon("mission"))
	var column := content(home, "ZonesScroll")
	var current := MenuSkin.panel(column, "panel", 8)
	var landscape := MenuSkin.icon(current, Art.OUTSKIRTS, Vector2(0,126))
	landscape.name = "CurrentZoneLandscape"
	MenuSkin.label(current, "01 · Blackout Outskirts", 22, Color("ffe2a0"), true)
	var clears := 0
	for mission in range(1,6):
		if "clear" in home.profile.data.missions.get(str(mission), []):
			clears += 1
	MenuSkin.label(current, "%d / 5 missions cleared" % clears, 13, Color("dbe7ff"), true)
	action(home, "Enter Outskirts", func(): home.navigate("mission"), current, "gold", 44)
	MenuSkin.label(column, "THE ROAD AHEAD", 14, Color("c5b3f4"), true)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 7)
	grid.add_theme_constant_override("v_separation", 7)
	column.add_child(grid)
	for index in range(1, home.ZONES.size()):
		var card := MenuSkin.panel(grid, "panel", 12)
		card.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
		MenuSkin.icon(card, Art.icon("mission"), Vector2(0,51)).modulate = Color("8a91b9")
		MenuSkin.label(card, "%02d" % (index+1), 20, Color("a7acd2"), true)
		MenuSkin.label(card, home.ZONES[index], 14, Color("c7cce3"), true)
		var locked := action(home, "Coming later", func(): pass, card, "disabled", 32)
		locked.disabled = true
		locked.add_theme_font_size_override("font_size", 12)
	MenuSkin.label(column, "Later zones are planned and not playable yet.", 12, Color("b7c9e9"), true)
	back(home, "mission", "Back to Expedition")
