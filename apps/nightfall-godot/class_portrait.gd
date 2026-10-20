extends Control
## The Class pedestal uses the exact articulated equipped actor used in combat.
const Actor = preload("res://gear_actor.gd")
var elapsed: float:
 get: return portrait.elapsed if portrait!=null else 0.0
var reduced := false
var class_id := ""
var portrait: Node2D
var appearance: Dictionary = {}

func configure(_texture: Texture2D, hero_id: String, reduce_motion: bool, equipped: Dictionary = {}) -> void:
 class_id=hero_id
 reduced=reduce_motion
 appearance=equipped.duplicate(true)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 portrait=Actor.new()
 portrait.name="ClassEquippedActor"
 portrait.class_id=class_id
 portrait.weapon_family=appearance.get("weapon","pistol")
 portrait.appearance=appearance
 portrait.reduced=reduced
 add_child(portrait)
 resized.connect(layout_actor)
 visibility_changed.connect(refresh_motion)
 layout_actor()
 refresh_motion()

func layout_actor() -> void:
 if portrait==null:return
 var factor:=minf(size.y*0.90/80.0,size.x/70.0)
 portrait.position=Vector2(size.x*0.5,size.y-18)
 portrait.scale=Vector2.ONE*factor

func refresh_motion() -> void:
 set_process(not reduced and is_visible_in_tree())
 if portrait!=null:portrait.refresh_motion()
