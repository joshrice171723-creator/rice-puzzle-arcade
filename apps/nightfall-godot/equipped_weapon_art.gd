extends RefCounted
## Weapon art is a separate layer, anchored to the same deformed hand as the body.
const ITEMS = preload("res://assets/menu-items.png")
const TEXTURES := {
	"scattergun":preload("res://assets/weapons/scattergun.png"),
	"crossbow":preload("res://assets/weapons/crossbow.png"),
	"wand":preload("res://assets/weapons/wand.png"),
	"sabre":preload("res://assets/weapons/sabre.png")}
const SPECS := {
	"pistol":{"grip":Vector2(0.28,0.72),"tip":Vector2(0.85,0.25),"size":28.0},
	"scattergun":{"grip":Vector2(0.22,0.69),"tip":Vector2(0.88,0.16),"size":34.0},
	"crossbow":{"grip":Vector2(0.32,0.66),"tip":Vector2(0.90,0.16),"size":40.0},
	"wand":{"grip":Vector2(0.40,0.67),"tip":Vector2(0.84,0.14),"size":42.0},
	"sabre":{"grip":Vector2(0.24,0.76),"tip":Vector2(0.90,0.14),"size":48.0}}
static var pistol: AtlasTexture

static func texture_for(family: String) -> Texture2D:
	if TEXTURES.has(family):
		return TEXTURES[family]
	if pistol == null:
		pistol = AtlasTexture.new()
		pistol.atlas = ITEMS
		pistol.region = Rect2(0,0,ITEMS.get_width()/4.0,ITEMS.get_height()/3.0)
		pistol.filter_clip = true
	return pistol

static func mount(family: String, hand: Vector2, aim: Vector2, age: float, attacking: bool) -> Transform2D:
	var spec: Dictionary = SPECS.get(family,SPECS.pistol)
	var direction := aim.normalized() if aim.length_squared() > 0.01 else Vector2.RIGHT
	var angle: float = direction.angle()-(spec.tip-spec.grip).angle()
	if attacking and age >= 0 and age < 0.24:
		if family == "sabre":
			angle += lerpf(-1.05,0.85,smoothstep(0.0,0.16,age))*(1-smoothstep(0.16,0.24,age))
		elif family == "wand":
			angle -= sin(clampf(age/0.24,0,1)*PI)*0.12
		else:
			angle -= (0.18 if family=="scattergun" else 0.09)*(1-smoothstep(0,0.18,age))
	var axis := Vector2.from_angle(angle)*float(spec.size)
	var transform := Transform2D(axis,Vector2(-axis.y,axis.x),hand)
	transform.origin -= transform.basis_xform(spec.grip)
	return transform

static func draw(canvas: Node2D, family: String, transform: Transform2D, tint: Color) -> void:
	canvas.draw_set_transform_matrix(transform)
	canvas.draw_texture_rect(texture_for(family),Rect2(0,0,1,1),false,tint)
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
