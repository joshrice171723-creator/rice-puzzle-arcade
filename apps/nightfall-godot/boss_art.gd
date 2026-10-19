extends RefCounted
## Two authored poses per boss. Explicit atlas regions preserve uneven margins.
const ART = preload("res://assets/bosses.png")
const REGIONS := [
	[Rect2(0, 0, 437, 389), Rect2(438, 0, 356, 389), Rect2(795, 0, 367, 389), Rect2(1163, 0, 404, 389), Rect2(1568, 0, 415, 389)],
	[Rect2(0, 390, 399, 403), Rect2(400, 390, 412, 403), Rect2(813, 390, 354, 403), Rect2(1168, 390, 399, 403), Rect2(1568, 390, 415, 403)]]
const SIZES := [Vector2(110, 100), Vector2(88, 94), Vector2(96, 100), Vector2(113, 108), Vector2(130, 124)]

static func texture(mission: int, windup: bool = false) -> AtlasTexture:
	var result := AtlasTexture.new()
	result.atlas = ART
	result.region = REGIONS[int(windup)][clampi(mission - 1, 0, 4)]
	return result

static func draw_boss(canvas: Node2D, enemy: Dictionary, mission: int, offset: Vector2) -> void:
	var index := clampi(mission - 1, 0, 4)
	var windup: bool = enemy.tell > 0 or enemy.rush_left > 0
	var size: Vector2 = SIZES[index]
	var reduced: bool = canvas.profile.data.settings.reduced_effects
	var flash: float = enemy.get("hit_flash", 0.0) / 0.12
	var recoil: Vector2 = enemy.get("hit_push", Vector2.ZERO) * flash if not reduced else Vector2.ZERO
	var at: Vector2 = enemy.pos + offset + recoil
	if not reduced:
		var breath := sin(canvas.anim_time * 2.8) * 0.012
		size *= Vector2(1.0 - breath, 1.0 + breath)
		if enemy.tell > 0:
			size *= Vector2(1.04, 0.97)
	var tint := Color.WHITE if reduced else Color.WHITE.lerp(Color(1.6,1.6,1.7), flash)
	canvas.draw_set_transform(at, 0, Vector2(enemy.face, 1))
	canvas.draw_texture_rect_region(ART, Rect2(Vector2(-size.x / 2, -size.y * 0.94), size), REGIONS[int(windup)][index], tint)
	canvas.draw_set_transform(Vector2.ZERO)
