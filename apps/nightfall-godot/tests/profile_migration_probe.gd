extends SceneTree
## Read-only verification against a supplied save backup, never a live save writer.
const Profile=preload("res://profile.gd")
const Run=preload("res://run.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String)->void:
	checks+=1
	if not ok:
		failures+=1
		push_error(label)
func _initialize()->void:
	var args=OS.get_cmdline_user_args()
	if args.is_empty() or not FileAccess.file_exists(args[0]):
		push_error("Pass an existing save backup path.")
		quit(1)
		return
	var source=FileAccess.get_file_as_string(args[0])
	var before: Dictionary=JSON.parse_string(source)
	var profile=Profile.new(args[0])
	before=profile.normalize_numbers(before)
	check(profile.load_save(),"Actual backup migrates and validates")
	for key in ["inventory","equipment","credits","parts","gems","missions","active_attempt","training_style"]:
		check(profile.data[key]==before[key],"Migration preserves "+key)
	if int(before.version)<6:
		var expected=profile.Training.migrate_legacy(before.combat_xp)
		for stat in profile.Training.STATS:
			check(profile.Training.level(profile.combat_experience()[stat])==profile.Training.level(expected[stat]),"Trained level preserved: "+stat)
	var saved: Dictionary=profile.saved_run()
	if not saved.is_empty():
		var run=Run.new()
		run.configure(profile.data.active_attempt.mission,profile.stats())
		check(run.restore(saved),"Actual saved expedition resumes under expanded world rules")
		check(run.BOUNDS.has_point(run.player) and run.elapsed==saved.combat.elapsed and run.kills==saved.combat.kills,"Resume preserves elapsed time and kills, with reachable world coordinates")
		check(run.snapshot().world_version==2,"Resaved expedition carries world migration marker")
	check(FileAccess.get_file_as_string(args[0])==source,"Read-only migration probe never rewrites the backup")
	print("Actual profile migration: %d checks, %d failures" %[checks,failures])
	quit(1 if failures else 0)
