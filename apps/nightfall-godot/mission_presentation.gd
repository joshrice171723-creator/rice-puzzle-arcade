extends RefCounted
## Bounded, presentation-only world accents. Feedback is owned and aged by Run.
const Shapes = preload("res://draw_shapes.gd")
const MenuSkin = preload("res://menu_skin.gd")
const MAX_FEEDBACK := 48
const MAX_VISIBLE_DAMAGE_LABELS := 8
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
		var at := Vector2(290.0 + fposmod(index * 554.0, 1820.0) + drift,
			310.0 + fposmod(index * 346.0, 1700.0) - cycle * 42.0) + offset
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
	Shapes.circle(canvas,Vector2.ZERO,16.0,Color(0.02,0.04,0.10,0.20))
	if not reduced:
		var breath := 0.13 + sin(time * 1.35) * 0.015
		Shapes.ring(canvas,Vector2.ZERO,18.0,1.0,Color(0.49,0.82,1.0,breath))
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_feedback(canvas: Node2D, run: RefCounted, offset: Vector2, reduced: bool, show_numbers: bool = true) -> void:
	var entries: Array = run.feedback
	var labels: Dictionary = {13: [], 18: [], 22: []}
	var visible_damage_labels := 0
	var spark_points := PackedVector2Array()
	var spark_colors := PackedColorArray()
	for index in range(mini(entries.size(), MAX_FEEDBACK) - 1, -1, -1):
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
		if kind in ["hit","hero_damage"]:
			var label := damage_label(item, at, direction, age, alpha, reduced) if show_numbers else {}
			if not label.is_empty() and visible_damage_labels < MAX_VISIBLE_DAMAGE_LABELS:
				labels[label.size].append(label)
				visible_damage_labels += 1
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
	var size := (22 if critical else 18) if not reduced else 13
	var position := at + Vector2(direction.x * age * (3.0 if reduced else 8.0), -24.0 - age * (9.0 if reduced else 42.0) - (sin(age*PI)*6.0 if not reduced else 0.0))
	position.x -= font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x * 0.5
	var color := Color("ff8296") if item.get("kind","") == "hero_damage" else (Color("ffd568") if critical else (CYAN if elemental else GOLD))
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
	var center := at + Vector2(0,-age * 15.0)
	var radius := 5.0 + age * 14.0
	var points := PackedVector2Array([center + Vector2(0,-radius), center + Vector2(radius,0), center + Vector2(0,radius), center + Vector2(-radius,0), center + Vector2(0,-radius)])
	canvas.draw_polyline(points, Color(1.0,0.90,0.65,alpha * 0.9), 1.6, true)
	for index in 4:
		var ray := Vector2.from_angle(index*TAU/4.0+0.4)
		canvas.draw_line(center+ray*radius*0.7,center+ray*(radius+4),Color(0.75,0.94,1,alpha),1.5,true)

static func draw_collectible(canvas: Node2D, texture: Texture2D, at: Vector2, size: Vector2, time: float, seed_value: int, color: Color, reduced: bool, attracted: bool = false, target: Vector2 = Vector2.ZERO) -> void:
	# Bounded immediate drawing: no per-loot nodes, particles, lights, or allocations of textures.
	var phase := time*3.5+float(seed_value)*1.71
	var center := at+Vector2(0,-2.0 if reduced else -3.0-sin(phase)*1.5)
	var halo := size*1.45
	canvas.draw_texture_rect(texture,Rect2(center-halo*0.5,halo),false,Color(color,0.18 if reduced else 0.22+0.06*sin(phase)))
	if attracted and not reduced:
		var axis := (target-at).normalized()
		canvas.draw_line(center-axis*5,center-axis*17,Color(color,0.45),2.0,true)
	canvas.draw_texture_rect(texture,Rect2(center-size*0.5,size),false)
	if not reduced:
		var shine := center+Vector2(size.x*0.22,-size.y*0.3)
		var length := 2.0+3.5*pow(maxf(0,sin(phase)),4)
		canvas.draw_line(shine-Vector2(length,0),shine+Vector2(length,0),Color(1,0.98,0.88,0.9),1.3,true)
		canvas.draw_line(shine-Vector2(0,length),shine+Vector2(0,length),Color(1,0.98,0.88,0.9),1.3,true)

static func muzzle_prongs(canvas: Node2D, at: Vector2, direction: Vector2, age: float, alpha: float) -> void:
	if age < 0 or age >= 1 or alpha <= 0:
		return
	var axis := direction.normalized() if direction.length_squared() > 0.01 else Vector2.RIGHT
	var side := axis.orthogonal()
	# A 30 ms directional gas cone, then a faint expanding smoke curl.
	var flash := 1.0-smoothstep(0.035,0.15,age)
	if flash > 0:
		var length := (7.5+alpha*1.5)*flash
		canvas.draw_colored_polygon(PackedVector2Array([at-side*2.2,at+axis*length-side*0.7,at+axis*(length+2),at+axis*length+side*0.7,at+side*2.2]),Color(1.0,0.64,0.19,minf(1,alpha)*flash))
		canvas.draw_line(at,at+axis*(length*0.70),Color(1,0.98,0.79,minf(1,alpha)*flash),2.1,true)
	if age > 0.10:
		var smoke := sin(clampf((age-0.10)/0.90,0,1)*PI)*minf(1,alpha)*0.20
		var center := at+axis*(3.0+age*6.0)+Vector2(0,-age*6.0)
		Shapes.circle(canvas,center,1.5+age*2.0,Color(0.68,0.72,0.77,smoke))
		Shapes.circle(canvas,center+side*1.1-axis*2.0,1.1+age*1.4,Color(0.76,0.78,0.83,smoke*0.65))
