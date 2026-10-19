extends RefCounted
## A single themed branching path at a time; preview and spending share this view.
const Skills = preload("res://skill_tree.gd")
const Haven = preload("res://haven_content.gd")
const Powers = preload("res://power_hud.gd")
const Art = preload("res://haven_art.gd")
const UI = preload("res://preparation_ui.gd")
const Showcase = preload("res://class_showcase.gd")
const ORDER = Showcase.ORDER
const POSITIONS := [Vector2(180,90),Vector2(93,191),Vector2(267,181),Vector2(65,287),Vector2(291,274),Vector2(175,384),Vector2(99,492),Vector2(271,484),Vector2(65,595),Vector2(297,590),Vector2(111,712),Vector2(258,704),Vector2(175,279),Vector2(181,594)]

class LockMarker extends Control:
 func _draw() -> void:
  draw_arc(Vector2(8,7),4.5,PI,TAU,12,Color("07152d"),5.0,true)
  draw_arc(Vector2(8,7),4.5,PI,TAU,12,Color("e0e9fa"),2.5,true)
  draw_rect(Rect2(0,6,16,12),Color("07152d"))
  draw_rect(Rect2(2,7,12,10),Color("c3d1e8"))
  draw_circle(Vector2(8,11),1.7,Color("23395f"))
  draw_line(Vector2(8,11),Vector2(8,15),Color("23395f"),2.0)

static func show_tree(home: Control) -> void:
 show_page(home,false)

static func show_page(home: Control, preview: bool = false) -> void:
 var profile: RefCounted=home.profile
 var class_id: String=home.inspected_class if not home.inspected_class.is_empty() else profile.data["class"]
 var branches: Array=Skills.branches(class_id)
 var ranks: Dictionary=profile.talent_ranks(class_id)
 var selected: String=home.tree_ability
 var branch: int=int(home.get_meta("talent_branch_"+class_id,0))
 var definition: Dictionary=Skills.node(class_id,selected)
 if not definition.is_empty():branch=definition.branch
 else:
  definition=Skills.branch_nodes(class_id,branch)[0]
  selected=definition.id
 var points: int=profile.skill_points(class_id)
 var summary:=HBoxContainer.new()
 summary.add_theme_constant_override("separation",6)
 home.body.add_child(summary)
 for direction in [-1,1]:
  if direction==1:
   var words:=VBoxContainer.new()
   words.size_flags_horizontal=Control.SIZE_EXPAND_FILL
   summary.add_child(words)
   UI.label_in(home,words,Haven.CLASSES[class_id].name+" Talents",19,Color("ffe2a0"))
   UI.label_in(home,words,"Combat %d/99 · %d points" % [profile.class_combat_level(class_id),points],13)
  var arrow: Button=home.button("‹" if direction<0 else "›",func():
   home.inspected_class=ORDER[posmod(ORDER.find(class_id)+direction,4)];home.tree_ability="";home.rebuild(),summary,44)
  arrow.name="TalentPreviousClass" if direction<0 else "TalentNextClass"
  arrow.custom_minimum_size=Vector2(42,50)
  arrow.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
  Showcase.action(arrow,false,28)
 var tabs:=HBoxContainer.new()
 tabs.add_theme_constant_override("separation",5)
 home.body.add_child(tabs)
 for index in branches.size():
  var info: Dictionary=branches[index]
  var used:=0
  for node in Skills.branch_nodes(class_id,index):used+=int(ranks.get(node.id,0))
  var tab: Button=home.button(info.name+"\n%d spent" % used,func():
   home.set_meta("talent_branch_"+class_id,index);home.tree_ability=Skills.branch_nodes(class_id,index)[0].id;home.rebuild(),tabs,44)
  tab.name="TalentBranch_"+str(index)
  tab.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  tab.add_theme_font_size_override("font_size",12)
  Showcase.action(tab,index==branch,12)
  tab.tooltip_text=info.description
 var diagram:=ScrollContainer.new()
 diagram.name="TalentConstellation" if preview else "ClassSkillTree"
 diagram.custom_minimum_size=Vector2(360,340)
 diagram.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 home.body.add_child(diagram)
 var board:=Control.new()
 board.name="TalentPath"
 board.custom_minimum_size=Vector2(360,1470)
 diagram.add_child(board)
 var backdrop:=ColorRect.new()
 backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 backdrop.color=Color("080f24")
 backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE
 board.add_child(backdrop)
 var portrait:=Art.picture(board,Showcase.hero_texture(class_id),Rect2(110,5,280,510))
 portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 portrait.modulate=Color(0.48,0.58,0.82,0.16)
 Showcase.caption(board,branches[branch].name,Rect2(42,8,276,29),21,Color("f5dc9d"))
 var all: Array=Skills.branch_nodes(class_id,branch)
 var positions: Dictionary={}
 for node in all:positions[node.id]=node.position
 for node in all:
  for parent: String in Skills.parents(class_id,node.id):
   if not positions.has(parent):continue
   var from: Vector2=positions[parent]
   var to: Vector2=positions[node.id]
   var direction: Vector2=(to-from).normalized()
   var start: Vector2=from+direction*30
   var end: Vector2=to-direction*34
   var learned: bool=int(ranks.get(parent,0))>=Skills.node(class_id,parent).max_rank
   var edge:=Line2D.new()
   edge.name="TalentLink"
   edge.width=2.0
   edge.default_color=Color("c6a768") if learned else Color("38425c")
   edge.points=PackedVector2Array([start,start.lerp(end,0.48)+Vector2(0,4),end])
   board.add_child(edge)
   var arrowhead:=Line2D.new()
   arrowhead.width=2.0
   arrowhead.default_color=edge.default_color
   arrowhead.points=PackedVector2Array([end-direction.rotated(-0.50)*8,end,end-direction.rotated(0.50)*8])
   board.add_child(arrowhead)
 for node in all:
  var rank: int=ranks.get(node.id,0)
  var available: bool=profile.class_unlocked(class_id)
  var ready: bool=available and Skills.requirement(class_id,node.id,ranks).is_empty()
  var center: Vector2=positions[node.id]
  var button:=Showcase.fixed_button(home,board,"",Rect2(center-Vector2(27,27),Vector2(54,54)),func():
   home.set_meta("talent_scroll_"+class_id+str(branch),diagram.scroll_vertical);home.tree_ability=node.id;home.rebuild())
  button.name=("TalentNode_" if preview else "Skill_")+node.id
  button.tooltip_text="%s · %d/%d\n%s" % [node.name,rank,node.max_rank,Skills.description(class_id,node.id)]
  for state in ["normal","hover","pressed"]:
   var face:=StyleBoxFlat.new()
   face.bg_color=Color("101b34")
   face.border_color=Color("ffe0a0") if node.id==selected else (Color("c8a261") if rank>0 else Color("50617d") if ready else Color("2b354c"))
   face.set_border_width_all(2)
   face.set_corner_radius_all(5 if not node.spell.is_empty() else 27)
   face.shadow_color=Color(0,0,0,0.6)
   face.shadow_size=4
   button.add_theme_stylebox_override(state,face)
  var icon:=Art.picture(button,icon_for(node),Rect2(8,7,38,38))
  icon.modulate=Color.WHITE if rank>0 or ready else Color("616c84")
  if not available or (rank==0 and not ready):
   var lock:=LockMarker.new()
   lock.name="LockedMarker";lock.position=Vector2(36,26);lock.size=Vector2(16,18);lock.mouse_filter=Control.MOUSE_FILTER_IGNORE
   button.add_child(lock)
  var badge:=PanelContainer.new()
  badge.position=Vector2(11,44);badge.size=Vector2(33,18);badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
  var face:=StyleBoxFlat.new()
  face.bg_color=Color("080e20");face.border_color=Color("bfa16c") if rank>0 else Color("3b4b68");face.set_border_width_all(1);face.set_corner_radius_all(3)
  badge.add_theme_stylebox_override("panel",face);button.add_child(badge)
  var rank_label:=UI.label_in(home,badge,"%d/%d" % [rank,node.max_rank],12,Color("ffe2a0") if rank>0 else Color("c2cde1"))
  rank_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;rank_label.autowrap_mode=TextServer.AUTOWRAP_OFF
  var title:=Showcase.caption(board,node.name,Rect2(center.x-65,center.y+39,130,18),13,Color("c8d4e8"))
  title.autowrap_mode=TextServer.AUTOWRAP_OFF;title.max_lines_visible=1;title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
 diagram.set_deferred("scroll_vertical",int(home.get_meta("talent_scroll_"+class_id+str(branch),0)))
 var detail:=UI.card(home,home.body,Color("8bb9ef"),7)
 detail.name="TalentDetail"
 UI.label_in(home,detail,"%s · %d/%d" % [definition.name,ranks.get(selected,0),definition.max_rank],16,Color("ffe2a0"))
 var description:=UI.label_in(home,detail,Skills.description(class_id,selected),11)
 description.max_lines_visible=2
 var requirement: String=Skills.requirement(class_id,selected,ranks)
 if not profile.class_unlocked(class_id):requirement=Haven.CLASSES[class_id].unlock
 elif ranks.get(selected,0)>=definition.max_rank:requirement="Maximum rank"
 elif requirement.is_empty():requirement="Next rank · 1 class point"
 UI.label_in(home,detail,requirement,11,Color("c5dcfa"))
 var actions:=HBoxContainer.new()
 actions.add_theme_constant_override("separation",6)
 home.body.add_child(actions)
 if preview:
  var tree: Button=home.button("Spend Points",func():home.page="skills";home.tree_ability=selected;home.rebuild(),actions,44)
  tree.name="TalentPreviewOpenTree";tree.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  var mastery: Button=home.button("Mastery",func():home.navigate("mastery"),actions,44)
  mastery.name="TalentPreviewOpenMastery";mastery.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 else:
  var rank_button: Button=home.button("Rank Up · 1",func():home.refresh(func():return profile.rank_talent(class_id,selected),"Talent rank saved."),actions,44)
  rank_button.name="UnlockSkill";rank_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  rank_button.disabled=not profile.can_change_loadout() or not profile.class_unlocked(class_id) or points<1 or ranks.get(selected,0)>=definition.max_rank or not Skills.requirement(class_id,selected,ranks).is_empty()
  home.MenuSkin.action(rank_button,"gold")
  var refund: Button=home.button("Refund",func():home.refresh(func():return profile.reset_talents(class_id),"Class points refunded."),actions,44)
  refund.name="RefundTalents";refund.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  refund.disabled=not profile.can_change_loadout() or not profile.class_unlocked(class_id) or ranks.is_empty()
  home.button("Class",func():home.navigate("class"),actions,44).size_flags_horizontal=Control.SIZE_EXPAND_FILL

static func icon_for(node: Dictionary) -> Texture2D:
 if not node.spell.is_empty():return Powers.texture_for(node.spell)
 var icon: String=node.get("icon","")
 if icon in Skills.Combat.SPELLS:return Powers.texture_for(icon)
 match icon:
  "hp":return Art.item("hp")
  "armor","shield","structure_hp":return Art.SHIELD
  "power","basic_damage":return Art.SWORD
  "pickup","interact_speed","capacity","secure":return Art.item("ring")
  "speed","dodge_cooldown":return Art.item("boots")
  "spell_damage","class_cooldown":return Powers.texture_for("gravity")
 return Art.icon("training")
