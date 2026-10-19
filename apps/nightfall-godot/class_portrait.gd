extends Control
## Grounded character motion for the Class showcase. No gameplay state is changed.
const IDLE_SHADER := """
shader_type canvas_item;
uniform float idle_time = 0.0;
uniform vec2 atlas_origin = vec2(0.0);
uniform vec2 atlas_span = vec2(1.0);
void fragment() {
 vec2 uv = (UV - atlas_origin) / atlas_span;
 float breath = sin(idle_time * 1.7);
 float sway = sin(idle_time * 0.85);
 float body = smoothstep(0.08, 0.25, uv.y) * (1.0 - smoothstep(0.65, 0.92, uv.y));
 float hair = (1.0 - smoothstep(0.23, 0.44, uv.y)) * smoothstep(0.03, 0.12, uv.y);
 float coat = smoothstep(0.42, 0.64, uv.y) * (1.0 - smoothstep(0.83, 0.96, uv.y));
 float edge = smoothstep(0.10, 0.30, abs(uv.x - 0.5));
 vec2 sample_uv = uv;
 sample_uv.x -= body * sway * 0.004;
 sample_uv.x -= body * (uv.x - 0.5) * breath * 0.012;
 sample_uv.x -= hair * sin(idle_time * 1.3 + uv.y * 8.0) * 0.004;
 sample_uv.x -= coat * edge * sin(idle_time * 1.8 + uv.y * 10.0) * 0.009;
 sample_uv.y += body * breath * 0.003;
 COLOR = texture(TEXTURE, atlas_origin + clamp(sample_uv, vec2(0.0), vec2(1.0)) * atlas_span);
}
"""
var elapsed := 0.0
var frame_wait := 0.0
var reduced := false
var class_id := ""
var portrait: TextureRect
var idle_material: ShaderMaterial
var hand := Vector2(0.823, 0.308)
var staff := Vector2(0.185, 0.113)

func configure(texture: Texture2D, hero_id: String, reduce_motion: bool) -> void:
	class_id = hero_id
	reduced = reduce_motion
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait = TextureRect.new()
	portrait.name = "ClassHeroPortrait"
	portrait.texture = texture
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(portrait)
	if not reduced:
		idle_material = ShaderMaterial.new()
		var shader := Shader.new()
		shader.code = IDLE_SHADER
		idle_material.shader = shader
		if texture is AtlasTexture:
			var dimensions := Vector2(texture.atlas.get_width(), texture.atlas.get_height())
			idle_material.set_shader_parameter("atlas_origin", texture.region.position / dimensions)
			idle_material.set_shader_parameter("atlas_span", texture.region.size / dimensions)
		portrait.material = idle_material
	visibility_changed.connect(refresh_motion)
	refresh_motion()

func refresh_motion() -> void:
	set_process(not reduced and is_visible_in_tree())
	queue_redraw()

func _process(delta: float) -> void:
	frame_wait += delta
	if frame_wait < 1.0 / 30.0:
		return
	elapsed += frame_wait
	frame_wait = 0.0
	idle_material.set_shader_parameter("idle_time", elapsed)
	queue_redraw()

func image_rect() -> Rect2:
	var source := portrait.texture.get_size()
	var scale_value := minf(size.x / source.x, size.y / source.y)
	var dimensions := source * scale_value
	return Rect2((size - dimensions) * 0.5, dimensions)

func _draw() -> void:
	if reduced or class_id != "arcanist" or portrait == null:
		return
	var rect := image_rect()
	var palm := rect.position + rect.size * hand
	var focus := rect.position + rect.size * staff
	var pulse := 0.5 + 0.5 * sin(elapsed * 2.2)
	for center in [palm, focus]:
		for ring in range(6, 0, -1):
			draw_circle(center, 3.0 + ring * 3.0, Color(0.44, 0.43, 1.0, (0.025 + pulse * 0.015) * (7 - ring)))
	var radius := 17.0 + pulse * 2.0
	draw_arc(palm, radius, elapsed * 1.1, elapsed * 1.1 + TAU * 0.72, 48, Color(0.79,0.60,1.0,0.78),1.2,true)
	draw_arc(palm, radius * 0.71, -elapsed * 1.4, -elapsed * 1.4 + TAU * 0.65, 40, Color(0.52,0.82,1.0,0.85),0.8,true)
	for index in 12:
		var phase := elapsed * (0.65 + float(index % 3) * 0.11) + index * 2.4
		var orbit := Vector2(cos(phase),sin(phase)*0.56) * (radius + index % 4 * 2)
		var alpha := 0.35 + 0.5 * (0.5 + 0.5 * sin(phase * 1.3))
		draw_circle(palm + orbit, 1.0 + float(index % 2) * 0.5, Color(0.78,0.80,1.0,alpha))
	for index in 7:
		var rise := fposmod(elapsed * 0.22 + index * 0.143, 1.0)
		var position_value := focus + Vector2(sin(index * 3.1 + elapsed) * 10.0, -rise * 40.0)
		draw_circle(position_value, 1.2, Color(0.71,0.61,1.0,sin(rise * PI) * 0.65))
