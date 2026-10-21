extends RefCounted
## Full-body frame renderer for the Arcanist art review draft.
## The 4x4 atlas is deliberately isolated so a rejected art pass is easy to remove.
const ATLAS: Texture2D = preload("res://assets/arcanist-gameplay-draft.png")
const REACTION_ATLAS: Texture2D = preload("res://assets/arcanist-motion-reactions-draft.png")
const CELL := 1254.0 / 4.0
const ACTOR_SIZE := Vector2(80, 80)
const CELL_EDGE_BLEED := 20.0

static func draw_motion(canvas: Node2D, pos: Vector2, offset: Vector2, face: float, clock: float, stride: float, move_blend: float, cast_age: float, dodge: float, reduced: bool, hurt: float, weapon_age: float, state: String) -> void:
	var last_face := float(canvas.get_meta("arcanist_last_face", face))
	var turn_from := float(canvas.get_meta("arcanist_turn_from", face))
	var turn_started := float(canvas.get_meta("arcanist_turn_started", -100.0))
	if face != last_face:
		turn_from = last_face
		turn_started = clock
		canvas.set_meta("arcanist_turn_from", turn_from)
		canvas.set_meta("arcanist_turn_started", turn_started)
		canvas.set_meta("arcanist_last_face", face)
	var last_blend := float(canvas.get_meta("arcanist_last_blend", move_blend))
	var motion_started := float(canvas.get_meta("arcanist_motion_started", -100.0))
	var motion_mode := str(canvas.get_meta("arcanist_motion_mode", ""))
	if move_blend - last_blend > 0.05:
		motion_started = clock
		motion_mode = "start"
	elif last_blend - move_blend > 0.05:
		motion_started = clock
		motion_mode = "stop"
	canvas.set_meta("arcanist_last_blend", move_blend)
	canvas.set_meta("arcanist_motion_started", motion_started)
	canvas.set_meta("arcanist_motion_mode", motion_mode)
	var last_hurt := float(canvas.get_meta("arcanist_last_hurt", 0.0))
	var hit_started := float(canvas.get_meta("arcanist_hit_started", -100.0))
	if hurt > 0.15 and (last_hurt <= 0.15 or hurt > last_hurt + 0.25):
		hit_started = clock
	canvas.set_meta("arcanist_last_hurt", hurt)
	canvas.set_meta("arcanist_hit_started", hit_started)
	var previous_state := str(canvas.get_meta("arcanist_last_state", state))
	var defeat_started := float(canvas.get_meta("arcanist_defeat_started", -100.0))
	if state == "defeat" and previous_state != "defeat":
		defeat_started = clock
	canvas.set_meta("arcanist_last_state", state)
	canvas.set_meta("arcanist_defeat_started", defeat_started)

	var row := 0
	var column := 0
	var texture := ATLAS
	var sprite_face := face
	if state == "defeat":
		texture = REACTION_ATLAS
		row = 3
		column = clampi(int(floor(maxf(0.0, clock - defeat_started) / 0.16)), 0, 3)
	elif dodge > 0.01:
		row = 3
		column = clampi(int(floor((1.0 - clampf(dodge, 0.0, 1.0)) * 4.0)), 0, 3)
	elif hurt > 0.15:
		texture = REACTION_ATLAS
		row = 2
		column = clampi(int(floor(maxf(0.0, clock - hit_started) / 0.045)), 0, 3)
	elif (cast_age >= -0.18 and cast_age < 0.34) or (weapon_age >= 0.0 and weapon_age < 0.30):
		row = 2
		var age := cast_age if cast_age < 0.34 else weapon_age
		# Column 2 bakes in a large orb; use the game's live spell VFX instead.
		column = 0 if age < 0.035 else (1 if age < 0.11 else 3)
	elif clock - turn_started < 0.24:
		texture = REACTION_ATLAS
		row = 0
		var progress := clampf((clock - turn_started) / 0.24, 0.0, 0.999)
		column = int(floor(progress * 4.0)) if turn_from > 0 else 3 - int(floor(progress * 4.0))
		sprite_face = 1.0
	elif clock - motion_started < 0.20 and motion_mode != "":
		texture = REACTION_ATLAS
		row = 1
		var progress := clampf((clock - motion_started) / 0.20, 0.0, 0.999)
		column = int(floor(progress * 3.0)) if motion_mode == "start" else 2 + int(floor(progress * 2.0))
	elif move_blend > 0.08:
		row = 1
		column = int(floor(fposmod(stride / TAU, 1.0) * 4.0))
	else:
		row = 0
		column = int(floor(fposmod(clock * 2.0, 4.0)))

	# The generated sheets let feet from one row spill into the next row's crop.
	var top_bleed := CELL_EDGE_BLEED if row > 0 else 0.0
	var source := Rect2(column * CELL, row * CELL + top_bleed, CELL, CELL - top_bleed)
	var actor_size := ACTOR_SIZE
	var pixel_scale := actor_size.y / CELL
	var actor_rect := Rect2(-actor_size.x / 2, -actor_size.y + top_bleed * pixel_scale, actor_size.x, source.size.y * pixel_scale)
	var transform := Transform2D(Vector2(sprite_face, 0), Vector2(0, 1), pos + offset + Vector2(0, 5.6))
	var tint := Color.WHITE.lerp(Color(1.7, 1.35, 1.25), hurt if not reduced else 0.0)
	if dodge > 0.0 and not reduced:
		var trail := transform
		trail.origin.x -= sprite_face * actor_size.x * 0.175 * dodge
		canvas.draw_set_transform_matrix(trail)
		canvas.draw_texture_rect_region(texture, actor_rect, source, Color(0.62, 0.77, 1, dodge * 0.18))
	canvas.draw_set_transform_matrix(transform)
	canvas.draw_texture_rect_region(texture, actor_rect, source, tint)
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
