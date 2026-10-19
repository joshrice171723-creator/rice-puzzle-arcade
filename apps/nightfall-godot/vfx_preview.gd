extends Node
## Debug-only disposable capture journey. Never loads or writes the player's profile.
var arena: Node2D
var clock := 0.0
var stage := -1
var samples: Array[Dictionary] = []
var stage_samples: Array[float] = []
var calls: Array[int] = []
var finished := false
var caption: Label
var dodge_shown := false

func _ready() -> void:
	caption = Label.new()
	caption.position = Vector2(12,610)
	caption.add_theme_font_size_override("font_size",12)
	caption.add_theme_color_override("font_outline_color",Color.BLACK)
	caption.add_theme_constant_override("outline_size",4)
	arena.hud_root.get_parent().add_child(caption)
	configure(0)

func configure(next: int) -> void:
	if not stage_samples.is_empty():
		stage_samples.sort()
		calls.sort()
		var total := 0.0
		for value in stage_samples:
			total += value
		samples.append({"stage":stage,"frames":stage_samples.size(),"mean_ms":total/stage_samples.size(),"p95_ms":stage_samples[int(stage_samples.size()*0.95)],"draw_calls_p95":calls[int(calls.size()*0.95)]})
		stage_samples.clear()
		calls.clear()
	stage = next
	if next == 4:
		finished = true
		arena.stick = Vector2.ZERO
		arena.run.paused = true
		var file := FileAccess.open("user://vfx-preview-metrics.json",FileAccess.WRITE)
		file.store_string(JSON.stringify({"os":OS.get_name(),"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"version":Engine.get_version_info().string,"fixture":"Disposable stationary targets; actual Run attacks and hit timing; not a campaign balance test","stages":samples},"\t"))
		caption.text = "VFX preview complete • no progress saved"
		return
	if next == 2:
		arena.stick = Vector2.ZERO
		arena.run.paused = true
		caption.text = "Pause check • no progress saved"
		return
	if next == 3:
		arena.run.paused = false
		arena.run.class_id = "engineer"
		arena.profile.data.settings.reduced_effects = true
		caption.text = "Reduced Effects • no progress saved"
		return
	arena.run = arena.Run.new(221)
	arena.run.configure(1,arena.profile.stats())
	arena.run.elapsed = 30
	arena.run.player = Vector2(600,610)
	arena.run.spawn_wait = 999
	arena.run.fire_wait = 999
	arena.run.class_wait = 999
	arena.run.field.sites[0].pos = Vector2(485,490)
	arena.run.field.sites[1].pos = Vector2(850,800)
	arena.run.spells = {"ember":{"rank":1,"wait":0.18}}
	if next == 1:
		arena.run.spells.merge({"frost":{"rank":1,"wait":1.1},"blades":{"rank":1,"wait":1.6},"wisp":{"rank":1,"wait":0.0},"ground":{"rank":1,"wait":0.2},"gravity":{"rank":1,"wait":2.3},"chain":{"rank":1,"wait":0.6},"lance":{"rank":1,"wait":3.0}})
	for n in (1 if next == 0 else 12):
		arena.run.spawn_enemy(false,["drifter","runner","spitter"][n%3])
		var enemy: Dictionary = arena.run.enemies.back()
		enemy.pos = arena.run.player+Vector2(135,-65) if next == 0 else arena.run.player+Vector2.from_angle(n*TAU/12)*145
		enemy.hp = 50000.0
		enemy.max_hp = 50000.0
		enemy.speed = 0
		enemy.attack_wait = 999
	arena.home.hide()
	arena.run.paused = false
	arena.last_screen = ""
	caption.text = "Ember Bolt • no progress saved" if next == 0 else "Overlapping abilities • no progress saved"

func _process(delta: float) -> void:
	if finished:
		return
	clock += delta
	var next := 0 if clock < 9 else (1 if clock < 23 else (2 if clock < 26 else (3 if clock < 38 else 4)))
	if next != stage:
		configure(next)
	if finished:
		return
	if clock > 1:
		stage_samples.append(delta*1000)
		calls.append(int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	# Exercise different real projectile directions without consuming a player save.
	if stage == 0 and not arena.run.enemies.is_empty():
		arena.run.enemies[0].pos = arena.run.player + (Vector2(-135,-65) if clock > 5 else Vector2(135,-65))
	if stage in [1,3]:
		arena.stick = Vector2.from_angle(clock*1.5)*0.45
		if clock > 16.5 and not dodge_shown:
			dodge_shown = true
			arena.run.dodge()
	if arena.run.phase == "upgrade":
		arena.run.choose_offer(0)
	if arena.run.phase == "shrine":
		arena.run.leave_shrine()
