extends RefCounted
## Bounded, presentation-only world accents. Feedback is owned and aged by Run.
const MenuSkin = preload("res://menu_skin.gd")
const MAX_FEEDBACK := 48
const EMBER_COUNT := 12
const INK := Color("08142b")
const CYAN := Color("9ddfff")
const GOLD := Color("ffe0a0")

static func draw_ambience(canvas: Node2D, run: RefCounted, offset: Vector2, time: float, reduced: bool) -> void:
	if reduced or run.mission != 1 or run.mode != "campaign" or run.practice or run.benchmark_count > 0:
		return
	var clock := maxf(0.0, time)
	var points := PackedVector2Array()
	var glows := PackedColorArray()
	var cores := PackedColorArray()
	for index in EMBER_COUNT:
		var cycle := fposmod(clock * 0.075 + index * 0.137, 1.0)
		var drift := sin(clock * 0.21 + index * 1.9) * 7.0
		var at := Vector2(145.0 + fposmod(index * 277.0, 910.0) + drift,
			155.0 + fposmod(index * 173.0, 850.0) - cycle * 42.0) + offset
		var fade := sin(cycle * PI) * 0.24
		var half := Vector2(0.0, 0.12 + (index % 3) * 0.18)
		points.append(at - half)
		points.append(at + half)
		glows.append(Color(1.0,0.72,0.35,fade * 0.12))
		cores.append(Color(1.0,0.80,0.50,fade))
	# Two geometry batches preserve individual fades without 24 circle submissions.
	canvas.draw_multiline_colors(points, glows, 4.7, true)
	canvas.draw_multiline_colors(points, cores, 1.8, true)

static func draw_player_ground(canvas: Node2D, run: RefCounted, offset: Vector2, time: float, reduced: bool) -> void:
	var at: Vector2 = run.player + offset + Vector2(0,2)
	canvas.draw_set_transform(at, 0.0, Vector2(1.0,0.34))
	canvas.draw_circle(Vector2.ZERO, 16.0, Color(0.02,0.04,0.10,0.20))
	if not reduced:
		var breath := 0.13 + sin(time * 1.35) * 0.015
		canvas.draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 24, Color(0.49,0.82,1.0,breath), 1.0, true)
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_feedback(canvas: Node2D, run: RefCounted, offset: Vector2, reduced: bool) -> void:
	var entries: Array = run.feedback
	var labels: Dictionary = {13: [], 15: [], 17: []}
	var spark_points := PackedVector2Array()
	var spark_colors := PackedColorArray()
	for index in mini(entries.size(), MAX_FEEDBACK):
		var item: Dictionary = entries[index]
		var duration: float = item.get("duration", 0.0)
		var life: float = item.get("life", 0.0)
		if duration <= 0.0 or life <= 0.0:
			continue
		var at: Vector2 = item.get("pos", Vector2.ZERO) + offset
		if not at.is_finite():
			continue
		var age := 1.0 - clampf(life / duration, 0.0, 1.0)
		var alpha := clampf((1.0 - age) * 3.5, 0.0, 1.0)
		var direction: Vector2 = item.get("direction", Vector2.RIGHT)
		if not direction.is_finite() or direction.length_squared() < 0.001:
			direction = Vector2.RIGHT
		else:
			direction = direction.normalized()
		var kind: String = item.get("kind", "")
		if kind == "hit":
			var label := damage_label(item, at, direction, age, alpha, reduced)
			if not label.is_empty():
				labels[label.size].append(label)
			if not reduced:
				append_hit_sparks(spark_points, spark_colors, at, direction, age, alpha, item.get("elemental", false))
		elif not reduced:
			match kind:
				"death": death_shards(canvas, at, age, alpha)
				"dodge": dodge_streaks(canvas, at, direction, age, alpha)
				"pickup": pickup_rune(canvas, at, age, alpha)
				"muzzle": muzzle_prongs(canvas, at, direction, age, alpha)
	if not spark_points.is_empty():
		canvas.draw_multiline_colors(spark_points, spark_colors, 1.2, true)
	var font: Font = MenuSkin.DISPLAY if MenuSkin.DISPLAY != null else ThemeDB.fallback_font
	# Atlas-compatible passes keep geometry and each font size together.
	for size: int in labels:
		for label: Dictionary in labels[size]:
			canvas.draw_string_outline(font, label.position, label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 3, Color(INK,label.alpha))
	for size: int in labels:
		for label: Dictionary in labels[size]:
			canvas.draw_string(font, label.position, label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, label.color)

static func damage_label(item: Dictionary, at: Vector2, direction: Vector2, age: float, alpha: float, reduced: bool) -> Dictionary:
	var amount: float = item.get("amount", 0.0)
	if not is_finite(amount) or amount <= 0.0:
		return {}
	var critical: bool = item.get("critical", false)
	var elemental: bool = item.get("elemental", false)
	var text := str(roundi(amount)) if is_equal_approx(amount, float(roundi(amount))) else ("<0.1" if amount < 0.1 else "%.1f" % amount)
	if critical and not reduced:
		text += "!"
	var font: Font = MenuSkin.DISPLAY if MenuSkin.DISPLAY != null else ThemeDB.fallback_font
	var size := (17 if critical else 15) if not reduced else 13
	var position := at + Vector2(direction.x * age * (3.0 if reduced else 8.0), -24.0 - age * (9.0 if reduced else 29.0))
	position.x -= font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5
	var color := Color("ffd568") if critical else (CYAN if elemental else GOLD)
	color.a = alpha
	return {"text": text, "position": position, "size": size, "color": color, "alpha": alpha}

static func append_hit_sparks(points: PackedVector2Array, colors: PackedColorArray, at: Vector2, direction: Vector2, age: float, alpha: float, elemental: bool) -> void:
	var color := CYAN if elemental else GOLD
	color.a = alpha * 0.70
	for index in 4:
		var ray := direction.rotated(index * TAU / 4.0 + 0.22)
		points.append(at + ray * (2.0 + age * 8.0))
		points.append(at + ray * (6.0 + age * 11.0))
		colors.append(color)

static func death_shards(canvas: Node2D, at: Vector2, age: float, alpha: float) -> void:
	for index in 4:
		var ray := Vector2.from_angle(index * TAU / 4.0 + 0.65)
		var center := at + ray * (3.0 + age * 14.0) + Vector2(0,age * 4.0)
		var side := ray.orthogonal()
		canvas.draw_colored_polygon(PackedVector2Array([center + ray * 3.0, center - ray * 2.0 + side * 1.4, center - ray * 2.0 - side * 1.4]), Color(0.61,0.75,0.91,alpha * 0.48))

static func dodge_streaks(canvas: Node2D, at: Vector2, direction: Vector2, age: float, alpha: float) -> void:
	for index in 3:
		var origin := at + direction.orthogonal() * (index - 1) * 4.0 - direction * age * 4.0
		canvas.draw_line(origin, origin - direction * (9.0 + age * 12.0), Color(0.57,0.83,1.0,alpha * 0.44), 1.5, true)

static func pickup_rune(canvas: Node2D, at: Vector2, age: float, alpha: float) -> void:
	var center := at + Vector2(0,-age * 9.0)
	var radius := 3.5 + age * 3.5
	var points := PackedVector2Array([center + Vector2(0,-radius), center + Vector2(radius,0), center + Vector2(0,radius), center + Vector2(-radius,0), center + Vector2(0,-radius)])
	canvas.draw_polyline(points, Color(1.0,0.84,0.55,alpha * 0.68), 1.1, true)

static func muzzle_prongs(canvas: Node2D, at: Vector2, direction: Vector2, age: float, alpha: float) -> void:
	for angle in [-0.42,0.0,0.42]:
		var ray := direction.rotated(angle)
		canvas.draw_line(at + ray * 2.0, at + ray * (7.0 + age * 2.0), Color(1.0,0.88,0.61,alpha * 0.78), 1.4, true)
