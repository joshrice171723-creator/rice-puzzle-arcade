extends Control
## Ambient menu motion. Callers omit these nodes when Reduced effects is enabled.
## Explicit local time freezes both drawing and hero shader when hidden.
const ROCKS = preload("res://assets/menu-outskirts.png")
const FRAME_STEP := 1.0 / 24.0
const HERO_SHADER := """
shader_type canvas_item;
uniform float idle_time = 0.0;
uniform vec2 atlas_origin = vec2(0.0);
uniform vec2 atlas_span = vec2(1.0);
void fragment() {
 vec2 local_uv = (UV - atlas_origin) / atlas_span;
 float torso = smoothstep(0.07, 0.28, local_uv.y) * (1.0 - smoothstep(0.60, 0.82, local_uv.y));
 float breath = sin(idle_time * 2.05);
 float weight = sin(idle_time * 0.93);
 vec2 sample_uv = local_uv;
 sample_uv.x -= torso * (weight * 0.003 + (local_uv.x - 0.5) * breath * 0.009);
 sample_uv.y += torso * breath * 0.0025;
 COLOR = texture(TEXTURE, atlas_origin + sample_uv * atlas_span);
}
"""
var kind := "background"
var beacon_uv := Vector2(0.52,0.075)
var warm_uv := [Vector2(0.28,0.46), Vector2(0.345,0.68)]
var elapsed := 0.0
var frame_wait := 0.0
var hero_material: ShaderMaterial
var grains: Array[Dictionary] = []
var rock_regions: Array[AtlasTexture] = []

static func background(parent: Control) -> Node:
	var motion := new()
	motion.name = "BackgroundMotion"
	motion.kind = "background"
	motion.position = Vector2.ZERO
	motion.size = parent.size
	parent.add_child(motion)
	return motion

static func island(parent: Control, rect: Rect2) -> Node:
	var motion := new()
	motion.name = "IslandMotion"
	motion.kind = "island"
	motion.position = rect.position
	motion.size = rect.size
	parent.add_child(motion)
	return motion

static func hero(node: TextureRect) -> Node:
	var motion := new()
	motion.name = "HeroIdle"
	motion.kind = "hero"
	var material := ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = HERO_SHADER
	material.shader = shader
	if node.texture is AtlasTexture:
		var atlas: AtlasTexture = node.texture
		var dimensions := Vector2(atlas.atlas.get_width(), atlas.atlas.get_height())
		material.set_shader_parameter("atlas_origin", atlas.region.position / dimensions)
		material.set_shader_parameter("atlas_span", atlas.region.size / dimensions)
	motion.hero_material = material
	node.material = material
	node.add_child(motion)
	return motion

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	visibility_changed.connect(refresh_visibility)
	if kind == "background":
		for index in 16:
			grains.append({"u": fmod(index * 0.6180339887, 1.0), "v": fmod(index * 0.41421356, 1.0), "speed": 0.008 + (index%5)*0.002, "radius": 0.75 + (index%3)*0.35, "phase": index*1.73})
	elif kind == "island":
		# Transparent isolated cliff chips already painted into Outskirts art.
		for bounds in [Rect2(122,815,34,57), Rect2(858,1061,43,51), Rect2(1117,987,40,41)]:
			var rock := AtlasTexture.new()
			rock.atlas = ROCKS
			rock.region = bounds
			rock.filter_clip = true
			rock_regions.append(rock)
		for index in 12:
			grains.append({"u": 0.12 + fmod(index*0.382,0.76), "phase": index*0.72, "speed": 0.13 + (index%4)*0.025})
	refresh_visibility()

func refresh_visibility() -> void:
	set_process(is_visible_in_tree())
	if is_visible_in_tree():
		queue_redraw()

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	frame_wait += delta
	if frame_wait < FRAME_STEP:
		return
	elapsed += frame_wait
	frame_wait = 0.0
	if kind == "hero":
		hero_material.set_shader_parameter("idle_time", elapsed)
	else:
		queue_redraw()

func _draw() -> void:
	if kind == "background":
		for grain in grains:
			var vertical: float = fposmod(grain.v - elapsed*grain.speed, 1.0)
			var horizontal: float = grain.u + sin(elapsed*0.20+grain.phase)*0.018
			var alpha: float = 0.12 + 0.18*(0.5+0.5*sin(elapsed*0.8+grain.phase))
			var point := Vector2(horizontal*size.x,vertical*size.y)
			draw_circle(point,grain.radius*2.4,Color(0.46,0.61,1.0,alpha*0.13))
			draw_circle(point,grain.radius,Color(0.68,0.77,1.0,alpha))
	elif kind == "island":
		# Fractional source coordinates align to the transparent Haven island.
		var beacon := size * beacon_uv
		var pulse := 0.5+0.5*sin(elapsed*1.8)
		glow(beacon, size.x*0.043*(0.9+pulse*0.15),Color(0.66,0.24,1.0,0.10+pulse*0.08))
		var flicker := 0.78+sin(elapsed*9.7)*0.10+sin(elapsed*14.3)*0.06
		glow(size * warm_uv[0],size.x*0.045,Color(1.0,0.48,0.08,0.10*flicker))
		glow(size * warm_uv[1],size.x*0.038,Color(1.0,0.56,0.12,0.16*flicker))
		for index in grains.size():
			var grain: Dictionary = grains[index]
			var phase: float = fposmod(elapsed*grain.speed+grain.phase,1.0)
			var opacity := sin(phase*PI)*0.38
			var drift := sin(phase*2.4+index)*0.012
			var point := Vector2((grain.u+drift)*size.x,(0.86+phase*0.18)*size.y)
			if index%3 == 0:
				var rock: AtlasTexture = rock_regions[index%rock_regions.size()]
				var width := size.x*(0.012+(index%2)*0.005)
				var dimensions := Vector2(width,width*rock.region.size.y/rock.region.size.x)
				draw_texture_rect(rock,Rect2(point,dimensions),false,Color(1,1,1,opacity))
			else:
				draw_circle(point,0.7+(index%3)*0.35,Color(0.62,0.66,0.80,opacity*0.75))

func glow(center: Vector2, radius: float, tint: Color) -> void:
	for ring in range(5,0,-1):
		var color := tint
		color.a *= float(6-ring)/20.0
		draw_circle(center,radius*float(ring)/3.0,color)
