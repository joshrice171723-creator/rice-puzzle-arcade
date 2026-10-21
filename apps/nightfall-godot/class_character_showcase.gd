extends SubViewport
## Small animated 2.5D class portrait built from the approved class artwork.
## This is a menu showcase; gameplay actors continue to use their own rigs.

const MODEL_PATHS := {
	"scavenger": "res://assets/class-showcase/idle_models/scavenger.glb",
	"warden": "res://assets/class-showcase/idle_models/warden.glb",
	"arcanist": "res://assets/class-showcase/idle_models/arcanist.glb",
	"engineer": "res://assets/class-showcase/idle_models/engineer.glb",
}

var class_id := "scavenger"
var character: Node3D
var animation_player: AnimationPlayer
var animation_name := ""


func configure(hero_id: String) -> void:
	class_id = hero_id
	# Supersample the painted silhouette so edge detail survives the phone-scale UI.
	size = Vector2i(560, 840)
	transparent_bg = true
	own_world_3d = true
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	build_world()
	build_character()
	build_camera()


func build_world() -> void:
	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.0, 0.0, 0.0, 0.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.75, 0.77, 0.9)
	environment.ambient_light_energy = 0.8
	world_environment.environment = environment
	add_child(world_environment)
	var stage := Node3D.new()
	stage.name = "ClassCharacterStage"
	add_child(stage)
	set_meta("stage", stage)


func build_character() -> void:
	var model_path: String = MODEL_PATHS.get(class_id, "")
	if model_path.is_empty():
		push_error("Unknown class showcase rig: " + class_id)
		return
	var bytes := FileAccess.get_file_as_bytes(model_path)
	if bytes.is_empty():
		push_error("Class showcase model is missing or empty: " + model_path)
		return
	var gltf := GLTFDocument.new()
	var gltf_state := GLTFState.new()
	var error := gltf.append_from_buffer(bytes, "", gltf_state)
	if error != OK:
		push_error("Could not read class showcase model %s: %s" % [class_id, error_string(error)])
		return
	character = gltf.generate_scene(gltf_state) as Node3D
	if character == null:
		push_error("Class showcase model did not create a 3D scene: " + class_id)
		return
	character.name = "ClassCharacter_" + class_id
	var stage := get_meta("stage") as Node3D
	stage.add_child(character)
	animation_player = find_animation_player(character)
	if animation_player == null:
		push_error("Class showcase model has no animation player: " + class_id)
		return
	for candidate in animation_player.get_animation_list():
		if str(candidate).to_lower() == "reset":
			continue
		var animation := animation_player.get_animation(candidate)
		animation.loop_mode = Animation.LOOP_LINEAR
		animation_name = str(candidate)
		break
	if animation_name.is_empty():
		push_error("Class showcase model has no idle animation: " + class_id)
		return
	animation_player.play(animation_name)


func build_camera() -> void:
	var scavenger := class_id == "scavenger"
	var target_y := 2.29 if scavenger else 1.73
	var camera := Camera3D.new()
	camera.name = "ClassShowcaseCamera"
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.07 if scavenger else 3.52
	camera.position = Vector3(0.0, target_y, 6.5)
	add_child(camera)
	camera.look_at(Vector3(0.0, target_y, 0.0), Vector3.UP)
	camera.current = true


func find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := find_animation_player(child)
		if found != null:
			return found
	return null
