extends Node

var music_player := AudioStreamPlayer.new()
var effects: Array[AudioStreamPlayer] = []
var tracks: Dictionary = {}
var cues: Dictionary = {}
var music_volume := 0.30
var sound_volume := 0.65
var current_track := ""
var slot := 0
var last_phase := ""
var last_hp := 0.0
var last_xp := 0
var last_structures := 0
var last_dodge := 0.0
var last_boss := -1
var pickup_wait := 0.0
var focused := true

func _exit_tree() -> void:
	music_player.stop()
	music_player.stream = null
	for player in effects:
		player.stop()
		player.stream = null
	tracks.clear()
	cues.clear()

func _ready() -> void:
	add_child(music_player)
	for index in 4:
		var player := AudioStreamPlayer.new()
		add_child(player)
		effects.append(player)
	for id in ["haven", "outskirts"]:
		var stream: AudioStreamWAV = load("res://assets/audio/%s.wav" % id)
		stream = stream.duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
		tracks[id] = stream
	for id in ["pickup", "hurt", "dodge", "build", "shrine", "upgrade", "victory", "defeat", "boss"]:
		cues[id] = load("res://assets/audio/%s.wav" % id)

func apply_settings(settings: Dictionary) -> void:
	music_volume = settings.music
	sound_volume = settings.sound

func cue(id: String) -> void:
	if sound_volume <= 0 or not focused or DisplayServer.get_name() == "headless":
		return
	var player := effects[slot]
	slot = (slot + 1) % effects.size()
	player.stream = cues[id]
	player.volume_db = linear_to_db(sound_volume * 0.5)
	player.play()

func tick(delta: float, run: RefCounted, at_haven: bool, ad_active: bool) -> void:
	pickup_wait = maxf(0, pickup_wait - delta)
	var desired := "haven" if at_haven else "outskirts"
	if desired != current_track:
		current_track = desired
		music_player.stream = tracks[desired]
		music_player.volume_db = -60
		music_player.play()
	var quiet := ad_active or not focused or DisplayServer.get_name() == "headless" or music_volume == 0
	music_player.stream_paused = quiet
	var target := linear_to_db(maxf(0.001, music_volume * (0.3 if run.paused and not at_haven else 0.55)))
	music_player.volume_db = move_toward(music_player.volume_db, target, delta * 35)
	if not at_haven and not ad_active:
		if run.phase != last_phase:
			if run.phase in ["victory", "defeat", "upgrade", "shrine"]:
				cue(run.phase)
		if run.health < last_hp:
			cue("hurt")
		if run.xp > last_xp and pickup_wait == 0:
			cue("pickup")
			pickup_wait = 0.12
		if run.defenses.structures.size() > last_structures:
			cue("build")
		if run.dodge_left > last_dodge:
			cue("dodge")
		if run.boss_id >= 0 and last_boss < 0:
			cue("boss")
	last_phase = run.phase
	last_hp = run.health
	last_xp = run.xp
	last_structures = run.defenses.structures.size()
	last_dodge = run.dodge_left
	last_boss = run.boss_id
	if quiet:
		for player in effects:
			player.stop()
