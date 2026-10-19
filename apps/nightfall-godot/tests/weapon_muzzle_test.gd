extends SceneTree
const Hero = preload("res://hero_cast.gd")
const Equipment = preload("res://equipped_weapon_art.gd")
const Effects = preload("res://combat_effects.gd")
const Weapons = preload("res://weapons.gd")
const Projectiles = preload("res://combat_projectiles.gd")
const Run = preload("res://run.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _initialize() -> void:
	for character in ["scavenger","engineer","warden","arcanist"]:
		for weapon in ["pistol","scattergun","crossbow","wand"]:
			for aim in [Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
				var face := -1.0 if aim.x < 0 else 1.0
				var attachment := Hero.weapon_attachment(character,weapon,face,aim,0.4,0,0,0,0,weapon,0)
				var muzzle := Hero.muzzle_offset(character,weapon,face,aim,0.4,0,0,0,0,weapon,0)
				check(muzzle.distance_to(attachment*Equipment.SPECS[weapon].tip)<0.0001,"Projectile and rendered weapon share the exact tip transform")
				var shot := {"kind":weapon,"pos":Vector2(600,600),"velocity":aim*500,"visual_launch":{"origin":Vector2(600,600),"aim":aim,"class_id":character,"face":face,"clock":0.4,"contact_distance":100.0}}
				var before := shot.duplicate(true)
				check(Effects.shot_visual_position(shot).distance_to(shot.pos+muzzle)<0.0001,"First visible point is the weapon muzzle in every aim quadrant")
				shot.pos += aim*80
				check(Effects.shot_visual_position(shot).distance_to(shot.pos+Effects.LIFT)<0.0001,"Projectile converges onto unchanged torso-height collision path")
				shot.pos = before.pos
				var previous := Effects.shot_visual_position(shot)
				for step in 80:
					shot.pos = before.pos+aim*float(step+1)
					var point := Effects.shot_visual_position(shot)
					check(point.distance_to(previous)<3.0,"Launch correction is continuous without a teleport")
					previous = point
				shot.pos = before.pos
				Effects.shot_visual_position(shot)
				check(shot==before,"Rendering never mutates projectile simulation or launch metadata")
	for weapon in ["pistol","scattergun","crossbow","wand"]:
		for distance in [10.0,25.0,50.0,150.0,500.0]:
			var with_visual := Run.new(427)
			var baseline := Run.new(427)
			for run in [with_visual,baseline]:
				run.weapon_id = weapon
				run.spawn_enemy()
				var enemy: Dictionary = run.enemies.back()
				enemy.pos = run.player+Vector2(distance,0)
				enemy.velocity = Vector2.ZERO
				Weapons.fire(run,enemy)
			for shot: Dictionary in baseline.shots:
				shot.erase("visual_launch")
			var hp: float = baseline.enemies[0].hp
			for shot: Dictionary in with_visual.shots:
				var simulation := shot.duplicate(true)
				Effects.shot_visual_position(shot)
				check(shot==simulation,"Close-target render projection cannot move the collision origin")
				shot.pos = shot.visual_launch.origin+Vector2(maxf(0,distance-17),0)
				if distance > 17:
					check(Effects.shot_visual_position(shot).distance_to(shot.pos+Effects.LIFT)<0.001,"Visual correction finishes by the close target collision boundary")
				shot.pos = simulation.pos
			Projectiles.friendly(with_visual,0.05)
			Projectiles.friendly(baseline,0.05)
			check(with_visual.enemies[0].hp==baseline.enemies[0].hp and with_visual.shots.size()==baseline.shots.size(),"Metadata preserves close hits, misses, pierce and range")
			if distance <= 25:
				check(with_visual.enemies[0].hp<hp,"An overlapping or nearby target still takes the original immediate hit")
	print("Nightfall weapon muzzle: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
