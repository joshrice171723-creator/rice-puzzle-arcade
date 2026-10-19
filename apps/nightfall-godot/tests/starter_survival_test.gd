extends SceneTree
const Run=preload("res://run.gd")
const Profile=preload("res://profile.gd")
## Opt-in deterministic acceptance route, not a player win-rate estimate.
var checks:=0
var failures:=0
func check(ok: bool,label: String)->void:
 checks+=1
 if not ok:
  failures+=1
  push_error(label)
func _initialize():
 for seed_value in [41]:
  var run=Run.new(seed_value)
  run.configure(1,Profile.new().stats())
  var steering:=Vector2.ZERO
  for frame in 30*480:
   if run.phase=="upgrade":run.choose_offer(0)
   if run.phase=="shrine":
    if run.field.sites[run.field.active_site].kind=="relic":run.choose_relic(0)
    else:run.leave_shrine()
   for enemy in run.enemies:
    if enemy.tell>0 and enemy.tell<0.2 and enemy.pos.distance_to(run.player)<(110 if enemy.boss else 65):run.dodge()
   if frame%6==0:steering=steer(run)
   run.tick(1.0/30,steering)

   if run.phase in ["victory","defeat"]:break
  check(run.phase=='victory' and run.elapsed>240,'Starter equipment can defeat the mandatory boss')
  check(run.damage_taken>0 and run.health>0 and run.kills>100,'Acceptance route uses real damage and live enemies')
  check(run.level>1 and not run.spells.is_empty(),'Earned run XP produces actual abilities')
  print("Starter probe seed %s: %s at %.1fs; %d kills; %.1fHP; %d run level; %s training" %[seed_value,run.phase,run.elapsed,run.kills,run.health,run.level,run.combat_xp])
 print('Starter survival: %d checks, %d failures' %[checks,failures])
 quit(1 if failures else 0)
static func steer(run: RefCounted) -> Vector2:
 var radial: Vector2=run.player-run.World.CENTER
 var goal: Vector2=run.World.CENTER+Vector2.from_angle(radial.angle()+0.5)*350
 var distance:=190.0
 for point: Vector2 in run.pickups:
  if point.distance_to(run.player)<distance:
   var threat: Dictionary=run.nearest_enemy(point,80)
   if threat.is_empty():
    goal=point;distance=point.distance_to(run.player)
 var best:=Vector2.ZERO
 var best_score:=-INF
 for index in 9:
  var direction: Vector2=run.player.direction_to(goal) if index==8 else Vector2.from_angle(index*TAU/8)
  var projected: Vector2=run.move_body(run.player,run.player+direction*52,10)
  var score: float=(run.player.distance_to(goal)-projected.distance_to(goal))*1.8
  score-=maxf(0,45-run.player.distance_to(projected))*8
  for enemy: Dictionary in run.enemies:
   if enemy.hp<=0:continue
   var separation: float=projected.distance_to(enemy.pos+enemy.get("velocity",Vector2.ZERO)*0.4)
   var safe: float=115 if enemy.boss else (90 if enemy.kind=="bulwark" else 75)
   if separation<safe:score-=pow((safe-separation)/safe,2)*250
  for shot: Dictionary in run.hostile_shots:
   if run.Projectiles.hit_time(shot.pos,shot.pos+shot.velocity*0.65,projected,25)!=INF:score-=90
  if score>best_score:
   best_score=score;best=direction
 return best
