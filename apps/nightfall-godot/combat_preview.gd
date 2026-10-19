extends Node
## Debug-only live combat review. Ordinary enemy HP/AI and player damage; separate profile.
const LOADOUTS := [
	{"class":"scavenger","weapon":"pistol","spells":["ember","frost","chain"],"branch":"","rank":1},
	{"class":"engineer","weapon":"scattergun","spells":["ground","wisp","blades"],"branch":"spread","rank":2},
	{"class":"warden","weapon":"sabre","spells":["frost","lance","ground"],"branch":"focus","rank":2},
	{"class":"arcanist","weapon":"wand","spells":["gravity","chain","ember"],"branch":"spread","rank":3},
	{"class":"scavenger","weapon":"crossbow","spells":["blades","wisp","lance"],"branch":"focus","rank":3}]
var arena: Node2D
var stage := -1
var elapsed := 0.0
var stage_elapsed := 0.0
var campaign := false
var finished := false
var frames: Array[float] = []
var samples: Array[Dictionary] = []
var caption: Label
var used_dodge := 0
var downs := 0
var report_at := 0.0
var capture_count := 0
var capturing := false
var last_frame_usec := 0
var stage_started_usec := 0
var physics_peak := 0.0
var draw_total := 0.0
var draw_peak := 0.0
var draw_sections: Dictionary = {}

func _ready() -> void:
	campaign = "--combat-campaign" in OS.get_cmdline_user_args()
	if FileAccess.file_exists("user://combat-preview.flag"):
		campaign = FileAccess.get_file_as_string("user://combat-preview.flag").strip_edges() == "campaign"
	caption = Label.new()
	caption.position = Vector2(12,602)
	caption.add_theme_font_size_override("font_size",11)
	caption.add_theme_color_override("font_outline_color",Color.BLACK)
	caption.add_theme_constant_override("outline_size",4)
	arena.hud_root.get_parent().add_child(caption)
	configure(0)

func record() -> void:
	if frames.is_empty():
		return
	frames.sort()
	var total := 0.0
	for frame in frames:
		total += frame
	samples.append({"stage":stage,"class":arena.run.class_id,"weapon":arena.run.weapon_id,"kills":arena.run.kills,"hp":arena.run.health,
		"phase":arena.run.phase,"seconds":arena.run.elapsed,"damage_taken":arena.run.damage_taken,"dodges":used_dodge,
		"mean_ms":total/frames.size(),"p95_ms":frames[int(frames.size()*0.95)],"render_fps":1000.0*frames.size()/maxf(1,total),"wall_seconds":(Time.get_ticks_usec()-stage_started_usec)/1000000.0,"frames":frames.size(),"physics_peak_ms":physics_peak,"draw_cpu_mean_ms":draw_total/maxi(1,frames.size()),"draw_cpu_peak_ms":draw_peak,"draw_sections_ms":averaged_sections()})
	frames.clear()

func averaged_sections() -> Dictionary:
	var result := {}
	for section: String in draw_sections:
		result[section] = draw_sections[section]/maxi(1,frames.size())
	return result

func configure(next: int) -> void:
	if stage >= 0:
		record()
		write_report(false)
	stage = next
	stage_elapsed = 0
	last_frame_usec = 0
	stage_started_usec = Time.get_ticks_usec()
	physics_peak = 0.0
	draw_total = 0.0
	draw_peak = 0.0
	draw_sections.clear()
	used_dodge = 0
	arena.physics_ms = 0
	arena.run = arena.Run.new(41 + next * 37)
	var stats: Dictionary = arena.profile.stats()
	if not campaign:
		var loadout: Dictionary = LOADOUTS[next % LOADOUTS.size()]
		arena.profile.data["class"] = loadout["class"]
		stats = arena.profile.stats()
		stats.weapon = loadout.weapon
	arena.run.configure(1 if campaign else (next % 5 + 1),stats)
	if not campaign:
		var loadout: Dictionary = LOADOUTS[next % LOADOUTS.size()]
		for index in loadout.spells.size():
			arena.run.spells[loadout.spells[index]] = {"rank":loadout.rank,"branch":loadout.branch,"wait":0.4+index*0.7,"evolved":loadout.rank==3}
		arena.run.elapsed = 105 if next < 5 else 239.9
		if next < 5:
			for index in 7:
				arena.run.spawn_enemy(false,["drifter","runner","spitter"][index%3])
				arena.run.enemies.back().pos = arena.run.player+Vector2.from_angle(index*TAU/7)*(105 if index%3 != 2 else 190)
		if next == 1:
			arena.run.defenses.place("turret",arena.run.player+Vector2(100,-30),40,true)
			arena.run.defenses.place("barricade",arena.run.player+Vector2(70,80),40,true)
	arena.home.hide()
	arena.run.paused = false
	arena.last_screen = ""
	caption.text = "Mission 1 • normal combat • review profile" if campaign else "%s · %s · live AI / practice loadout" % [stats["class"].capitalize(),stats.weapon.capitalize()]

static func steer(run: RefCounted) -> Vector2:
	var nearest: Dictionary = run.nearest_enemy(run.player,450)
	var desired := Vector2(600,600)+Vector2.from_angle(run.elapsed*0.20)*205
	# Collect earned XP when the approach is clear; otherwise skirt the nearest threat.
	var pickup: Vector2 = desired
	var pickup_distance := 160.0
	for point: Vector2 in run.pickups:
		var distance := point.distance_to(run.player)
		if distance < pickup_distance:
			pickup = point
			pickup_distance = distance
	var direction: Vector2 = run.player.direction_to(pickup)
	if not nearest.is_empty():
		var away: Vector2 = nearest.pos.direction_to(run.player)
		var separation: float = nearest.pos.distance_to(run.player)
		var safe_distance := 46.0 if run.weapon_id == "sabre" else 92.0
		if separation < safe_distance:
			direction = (away*1.3+away.orthogonal()*0.65+direction*0.25).normalized()
		elif run.weapon_id == "sabre" and separation > 65:
			direction = run.player.direction_to(nearest.pos)
	var edge := Vector2.ZERO
	if run.player.x < 205: edge.x = 1
	if run.player.x > 995: edge.x = -1
	if run.player.y < 205: edge.y = 1
	if run.player.y > 995: edge.y = -1
	return (direction+edge*2).normalized()

func _process(delta: float) -> void:
	if finished:
		return
	elapsed += delta
	stage_elapsed += delta
	var now := Time.get_ticks_usec()
	if last_frame_usec > 0:
		frames.append((now-last_frame_usec)/1000.0)
	last_frame_usec = now
	physics_peak = maxf(physics_peak,arena.physics_ms)
	draw_total += arena.draw_cpu_ms
	draw_peak = maxf(draw_peak,arena.draw_cpu_ms)
	for section: String in arena.draw_profile:
		draw_sections[section] = draw_sections.get(section,0.0)+arena.draw_profile[section]
	if elapsed >= report_at:
		report_at = elapsed+8
		print("Combat review: stage %d, %.1fs, phase %s, %.1f HP, %d kills, %d enemies" % [stage,arena.run.elapsed,arena.run.phase,arena.run.health,arena.run.kills,arena.run.enemies.size()])
		if "--combat-captures" in OS.get_cmdline_user_args() and not capturing and capture_count < 100:
			capture_frame()
	var run: RefCounted = arena.run
	if run.phase == "upgrade":
		run.choose_offer(0)
	if run.phase == "shrine":
		if run.field.sites[run.field.active_site].kind == "relic":
			run.choose_relic(0)
		else:
			run.leave_shrine()
	arena.stick = steer(run) if campaign or stage_elapsed > 3.0 else Vector2.ZERO
	var danger := false
	for enemy: Dictionary in run.enemies:
		if enemy.tell > 0 and enemy.tell < 0.20 and enemy.pos.distance_to(run.player) < (110 if enemy.boss else 65):
			danger = true
	if danger and run.dodge():
		used_dodge += 1
	if campaign:
		if run.phase in ["victory","defeat"] or elapsed > 420:
			finish()
	elif run.phase in ["victory","defeat"] or stage_elapsed > (45.0 if stage >= 5 else 24.0):
		if run.phase == "defeat":
			downs += 1
		if stage >= 9:
			finish()
		else:
			configure(stage+1)

func finish() -> void:
	record()
	finished = true
	arena.stick = Vector2.ZERO
	arena.run.paused = true
	write_report(true)
	caption.text = "Combat review complete • no campaign progress saved"
	print("Nightfall combat review complete: ","campaign" if campaign else "roster")
	if "--combat-quit" in OS.get_cmdline_user_args():
		get_tree().quit()

func write_report(complete: bool) -> void:
	var path := "user://combat-campaign-metrics.json" if campaign else "user://combat-roster-metrics.json"
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"complete":complete,"fixture":"normal starter mission" if campaign else "practice loadouts, live AI, normal enemy health and damage", "os":OS.get_name(),"adapter":RenderingServer.get_video_adapter_name(),"stages":samples,"downs":downs},"\t"))

func capture_frame() -> void:
	capturing = true
	var directory := "user://combat-review-captures"
	DirAccess.make_dir_recursive_absolute(directory)
	await RenderingServer.frame_post_draw
	arena.get_viewport().get_texture().get_image().save_png(directory.path_join("%s-%03d.png" % ["campaign" if campaign else "roster",capture_count]))
	capture_count += 1
	capturing = false
