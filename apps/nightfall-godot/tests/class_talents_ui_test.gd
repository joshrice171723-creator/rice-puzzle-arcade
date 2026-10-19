extends SceneTree
const Profile=preload("res://profile.gd")
const Training=preload("res://combat_progression.gd")
const Skills=preload("res://skill_tree.gd")
const Showcase=preload("res://class_showcase.gd")
const PATH="user://nightfall_class_tree_ui_fixture.json"
var checks:=0
var failures:=0
var capture_dir:=""
func _initialize() -> void:
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--capture-dir="):capture_dir=arg.trim_prefix("--capture-dir=")
 call_deferred("verify")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func settle() -> void:
 for frame in 5:await process_frame
func capture(label: String) -> void:
 if not capture_dir.is_empty() and DisplayServer.get_name()!="headless":
  DirAccess.make_dir_recursive_absolute(capture_dir)
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(capture_dir.path_join(label+".png"))
func verify() -> void:
 var profile=Profile.new(PATH)
 profile.save()
 var arena=load("res://main.tscn").instantiate()
 arena.testing=true;arena.profile=profile
 root.add_child(arena);arena.set_physics_process(false);arena.home.show()
 var home: Control=arena.home
 for dimensions in [Vector2i(430,760),Vector2i(320,568)]:
  root.size=dimensions
  for id in Skills.STARTERS:
   for page in ["talents","skills"]:
    home.inspected_class=id;home.tree_ability="";home.page=page;home.rebuild();await settle()
    for branch in 3:
     var before: Dictionary=profile.data.duplicate(true)
     home.find_child("TalentBranch_"+str(branch),true,false).pressed.emit();await settle()
     check(profile.data==before,"Branch browsing is read-only")
     check(home.body.get_global_rect().end.y<=home.navigation.position.y,"Sticky details and actions fit "+str(dimensions))
     var primary: Button=home.find_child("TalentPreviewOpenTree" if page=="talents" else "UnlockSkill",true,false)
     check(primary.get_global_rect().end.y<=home.navigation.position.y,"Actual sticky action fits above navigation "+str(dimensions))
     var all: Array=Skills.branch_nodes(id,branch)
     for definition in all:
      var actual: Button=home.find_child(("TalentNode_" if page=="talents" else "Skill_")+definition.id,true,false)
      var gated: bool=not profile.class_unlocked(id) or not Skills.requirement(id,definition.id,profile.talent_ranks(id)).is_empty()
      check(actual!=null and actual.has_node("LockedMarker")==gated,"Real prerequisite lock "+definition.id)
      check(actual.size.x>=44 and actual.size.y>=44,"Node tap area "+definition.id)
     var arrow: Button=home.find_child("TalentPreviousClass",true,false)
     check(arrow.get_theme_font_size("font_size")==28 and arrow.get_theme_stylebox("normal").texture==Showcase.texture("blue"),"Talent arrows share Class/Expedition style")
     check((home.find_child("UnlockSkill",true,false)==null)==(page=="talents"),"Preview has no spending control")
     var diagram: ScrollContainer=home.find_child("TalentConstellation" if page=="talents" else "ClassSkillTree",true,false)
     diagram.scroll_vertical=0
     await settle()
     await capture("%s-%s-%d-%d" % [id,page,branch,dimensions.x])
     diagram.scroll_vertical=450
     home.find_child(("TalentNode_" if page=="talents" else "Skill_")+all[5].id,true,false).pressed.emit();await settle()
     diagram=home.find_child("TalentConstellation" if page=="talents" else "ClassSkillTree",true,false)
     check(diagram.scroll_vertical>=400 and profile.data==before,"Inspection preserves scroll and never spends")
     if id=="scavenger":await capture("%s-%s-%d-%d-mid" % [id,page,branch,dimensions.x])
 home.inspected_class="scavenger";home.tree_ability="precision_sure_shot";home.page="skills";home.rebuild();await settle()
 home.find_child("UnlockSkill",true,false).pressed.emit();await settle()
 check(profile.talent_ranks("scavenger").get("precision_sure_shot",0)==1 and profile.skill_points("scavenger")==0,"Actual rank button spends one point")
 check(not home.find_child("Skill_precision_sure_shot",true,false).has_node("LockedMarker"),"Owned talent shows rank instead of lock")
 home.find_child("RefundTalents",true,false).pressed.emit();await settle()
 check(profile.talent_ranks("scavenger").is_empty() and profile.skill_points("scavenger")==1,"Refund returns class points")
 profile.data.active_attempt={"id":44};home.rebuild();await settle()
 check(home.find_child("UnlockSkill",true,false).disabled and home.find_child("RefundTalents",true,false).disabled,"Active run blocks spending/refund")
 check(arena.attempt_id==0,"Fixtures do not start expeditions")
 arena.queue_free();await process_frame
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(PATH+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH+suffix))
 print("Class talent UI: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
