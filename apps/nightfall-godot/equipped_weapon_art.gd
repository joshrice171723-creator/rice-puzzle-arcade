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

static func kick(family: String, age: float) -> float:
	if age < 0 or age >= 0.24:
		return 0.0
	# Impulse at release, then a damped return; no anticipatory gun bob.
	var strength := 3.8 if family == "scattergun" else (0.75 if family == "crossbow" else 1.5)
	return strength * exp(-age * (18.0 if family == "crossbow" else 23.0)) * (1.0-smoothstep(0.16,0.24,age))

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
			# Kick rises toward screen-up regardless of the aim quadrant.
			angle -= (0.035 if family == "crossbow" else (0.10 if family == "scattergun" else 0.055)) * (1.0 if direction.x >= 0 else -1.0) * kick(family,age) / (3.8 if family == "scattergun" else 1.5)
	var axis := Vector2.from_angle(angle)*float(spec.size)
	var transform := Transform2D(axis,Vector2(-axis.y,axis.x),hand)
	transform.origin -= transform.basis_xform(spec.grip)
	return transform

static func draw(canvas: Node2D, family: String, transform: Transform2D, tint: Color) -> void:
	canvas.draw_set_transform_matrix(transform)
	canvas.draw_texture_rect(texture_for(family),Rect2(0,0,1,1),false,tint)
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)

static func mechanism(canvas: Node2D, family: String, mount_transform: Transform2D, age: float, tint: Color) -> void:
	if age < 0 or age >= 0.24 or family not in ["pistol","scattergun","crossbow"]:
		return
	var spec: Dictionary = SPECS[family]
	var direction: Vector2 = (mount_transform*spec.tip-mount_transform*spec.grip).normalized()
	var side := direction.orthogonal()
	var barrel: Vector2 = mount_transform*(spec.grip.lerp(spec.tip,0.58))
	if family == "crossbow":
		var settle := sin(age*95.0)*exp(-age*23.0)*1.7
		var limbs := PackedVector2Array([barrel+side*7.0,barrel-direction*(3.0+settle),barrel-side*7.0])
		canvas.draw_polyline(limbs,Color(0.90,0.88,0.75,tint.a*0.75),0.8,true)
	elif age < 0.10:
		var slide := kick(family,age)*(0.75 if family == "pistol" else 0.35)
		canvas.draw_line(barrel-direction*(4.0+slide)-side*1.1,barrel+direction*(1.0-slide)-side*1.1,Color(0.77,0.85,0.92,tint.a*0.80),1.1,true)
