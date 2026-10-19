extends Node2D
## The Gear showcase uses the same body and held equipment as live combat.
const Hero = preload("res://hero_cast.gd")
var class_id := "scavenger"
var weapon_family := "pistol"
var reduced := false
var elapsed := 0.0
var frame_wait := 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	visibility_changed.connect(refresh_motion)
	refresh_motion()

func refresh_motion() -> void:
	set_process(not reduced and is_visible_in_tree())
	queue_redraw()

func _process(delta: float) -> void:
	frame_wait += delta
	if frame_wait < 1.0/30.0:
		return
	elapsed += frame_wait
	frame_wait = 0.0
	queue_redraw()

func _draw() -> void:
	Hero.draw_motion(self,Vector2.ZERO,Vector2.ZERO,1,elapsed,0,0,99,0,class_id=="engineer",reduced,class_id,0,"",weapon_family,Vector2(0.6,-0.8))
