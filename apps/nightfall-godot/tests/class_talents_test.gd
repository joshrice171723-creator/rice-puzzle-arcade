extends SceneTree
const Profile = preload("res://profile.gd")
const Training = preload("res://combat_progression.gd")
const Skills = preload("res://skill_tree.gd")
const EXAMPLES = [
 {
  "class": "scavenger",
  "budget": 1,
  "allocation": {
   "precision_sure_shot": 1
  },
  "effects": {
   "basic_damage": 0.02
  },
  "branch_points": [
   {
    "branch": "Precision",
    "points": 1
   },
   {
    "branch": "Scavenge",
    "points": 0
   },
   {
    "branch": "Mobility",
    "points": 0
   }
  ]
 },
 {
  "class": "scavenger",
  "budget": 25,
  "allocation": {
   "precision_sure_shot": 5,
   "blades": 1,
   "precision_spectral_edge": 5,
   "lance": 1,
   "precision_needlepoint": 5,
   "precision_quick_blades": 4,
   "precision_lance_drill": 4
  },
  "effects": {
   "basic_damage": 0.1,
   "spell_damage_by_id": {
    "blades": 0.2,
    "lance": 0.2
   },
   "spell_cooldown_by_id": {
    "blades": 0.08,
    "lance": 0.08
   }
  },
  "branch_points": [
   {
    "branch": "Precision",
    "points": 25
   },
   {
    "branch": "Scavenge",
    "points": 0
   },
   {
    "branch": "Mobility",
    "points": 0
   }
  ]
 },
 {
  "class": "scavenger",
  "budget": 50,
  "allocation": {
   "precision_sure_shot": 5,
   "blades": 1,
   "precision_spectral_edge": 5,
   "lance": 1,
   "precision_needlepoint": 5,
   "precision_quick_blades": 4,
   "precision_lance_drill": 4,
   "precision_measured_fire": 4,
   "mobility_light_foot": 5,
   "mobility_rolling_escape": 3,
   "precision_phase_rhythm": 4,
   "precision_braced_aim": 3,
   "precision_conductive_shot": 3,
   "precision_quick_relay": 3
  },
  "effects": {
   "basic_damage": 0.16,
   "spell_damage_by_id": {
    "blades": 0.2,
    "lance": 0.2,
    "chain": 0.15000000000000002
   },
   "spell_cooldown_by_id": {
    "blades": 0.08,
    "lance": 0.08,
    "chain": 0.09
   },
   "class_cooldown": 0.08,
   "armor": 6,
   "speed": 0.05,
   "dodge_cooldown": 0.06
  },
  "branch_points": [
   {
    "branch": "Precision",
    "points": 42
   },
   {
    "branch": "Scavenge",
    "points": 0
   },
   {
    "branch": "Mobility",
    "points": 8
   }
  ]
 },
 {
  "class": "scavenger",
  "budget": 99,
  "allocation": {
   "precision_sure_shot": 5,
   "blades": 1,
   "precision_spectral_edge": 5,
   "lance": 1,
   "precision_needlepoint": 5,
   "precision_quick_blades": 4,
   "precision_lance_drill": 4,
   "precision_measured_fire": 4,
   "mobility_light_foot": 5,
   "mobility_rolling_escape": 5,
   "precision_phase_rhythm": 4,
   "precision_braced_aim": 3,
   "precision_conductive_shot": 3,
   "precision_quick_relay": 3,
   "mobility_phase_practice": 5,
   "gravity": 1,
   "mobility_clearing_knot": 4,
   "precision_storm_followthrough": 3,
   "precision_deadeye": 2,
   "mobility_knot_rhythm": 4,
   "mobility_winter_shelter": 4,
   "mobility_cold_wake": 4,
   "mobility_winter_rhythm": 3,
   "mobility_second_wind": 3,
   "mobility_unburdened": 3,
   "mobility_covering_turret": 3,
   "mobility_emergency_dressings": 2,
   "scavenge_trail_finder": 5,
   "scavenge_practiced_hands": 1
  },
  "effects": {
   "basic_damage": 0.2,
   "spell_damage_by_id": {
    "blades": 0.2,
    "lance": 0.2,
    "chain": 0.24000000000000002,
    "gravity": 0.16,
    "frost": 0.16
   },
   "spell_cooldown_by_id": {
    "blades": 0.08,
    "lance": 0.08,
    "chain": 0.09,
    "gravity": 0.08,
    "frost": 0.09
   },
   "class_cooldown": 0.18,
   "armor": 6,
   "pickup": 0.2,
   "interact_speed": 0.03,
   "speed": 0.08,
   "dodge_cooldown": 0.17500000000000002,
   "shield": 0.1,
   "structure_damage": 0.12,
   "medkit": 0.01
  },
  "branch_points": [
   {
    "branch": "Precision",
    "points": 47
   },
   {
    "branch": "Scavenge",
    "points": 6
   },
   {
    "branch": "Mobility",
    "points": 46
   }
  ]
 },
 {
  "class": "engineer",
  "budget": 1,
  "allocation": {
   "machines_calibrated_turrets": 1
  },
  "effects": {
   "structure_damage": 0.03
  },
  "branch_points": [
   {
    "branch": "Machines",
    "points": 1
   },
   {
    "branch": "Energy",
    "points": 0
   },
   {
    "branch": "Fortification",
    "points": 0
   }
  ]
 },
 {
  "class": "engineer",
  "budget": 25,
  "allocation": {
   "machines_calibrated_turrets": 5,
   "machines_reinforced_chassis": 5,
   "machines_sidearm_drills": 5,
   "machines_service_tools": 4,
   "blades": 1,
   "machines_spectral_cutters": 4,
   "machines_drive_calibration": 1
  },
  "effects": {
   "structure_damage": 0.16499999999999998,
   "structure_hp": 0.2,
   "basic_damage": 0.1,
   "repair": 0.16,
   "spell_damage_by_id": {
    "blades": 0.16
   }
  },
  "branch_points": [
   {
    "branch": "Machines",
    "points": 25
   },
   {
    "branch": "Energy",
    "points": 0
   },
   {
    "branch": "Fortification",
    "points": 0
   }
  ]
 },
 {
  "class": "engineer",
  "budget": 50,
  "allocation": {
   "machines_calibrated_turrets": 5,
   "machines_reinforced_chassis": 5,
   "machines_sidearm_drills": 5,
   "machines_service_tools": 4,
   "blades": 1,
   "machines_spectral_cutters": 4,
   "machines_drive_calibration": 4,
   "fortification_worksite_resolve": 5,
   "fortification_plate_harness": 3,
   "lance": 1,
   "machines_piledriver": 4,
   "machines_redundant_bracing": 3,
   "machines_cutter_timing": 3,
   "machines_piston_timing": 3
  },
  "effects": {
   "structure_damage": 0.21,
   "structure_hp": 0.29000000000000004,
   "basic_damage": 0.1,
   "repair": 0.16,
   "spell_damage_by_id": {
    "blades": 0.16,
    "lance": 0.16
   },
   "spell_cooldown_by_id": {
    "blades": 0.09,
    "lance": 0.09
   },
   "hp": 0.1,
   "armor": 6
  },
  "branch_points": [
   {
    "branch": "Machines",
    "points": 42
   },
   {
    "branch": "Energy",
    "points": 0
   },
   {
    "branch": "Fortification",
    "points": 8
   }
  ]
 },
 {
  "class": "engineer",
  "budget": 99,
  "allocation": {
   "machines_calibrated_turrets": 5,
   "machines_reinforced_chassis": 5,
   "machines_sidearm_drills": 5,
   "machines_service_tools": 4,
   "blades": 1,
   "machines_spectral_cutters": 4,
   "machines_drive_calibration": 4,
   "fortification_worksite_resolve": 5,
   "fortification_plate_harness": 5,
   "lance": 1,
   "machines_piledriver": 4,
   "machines_redundant_bracing": 3,
   "machines_cutter_timing": 3,
   "machines_piston_timing": 3,
   "fortification_shield_lattice": 5,
   "fortification_rapid_setup": 4,
   "machines_precision_repairs": 3,
   "machines_siege_calibration": 2,
   "ground": 1,
   "fortification_anchored_ground": 4,
   "fortification_ground_cycling": 4,
   "fortification_exit_route": 4,
   "fortification_enduring_crew": 3,
   "fortification_riveted_plates": 3,
   "fortification_field_triage": 3,
   "fortification_supply_sweep": 3,
   "fortification_layered_lattice": 2,
   "energy_swarm_cycling": 5,
   "energy_charged_relay": 1
  },
  "effects": {
   "structure_damage": 0.25,
   "structure_hp": 0.29000000000000004,
   "basic_damage": 0.1,
   "repair": 0.28,
   "spell_damage_by_id": {
    "blades": 0.16,
    "lance": 0.16,
    "chain": 0.04,
    "ground": 0.16
   },
   "spell_cooldown_by_id": {
    "blades": 0.09,
    "lance": 0.09,
    "ground": 0.08
   },
   "class_cooldown": 0.1,
   "hp": 0.16,
   "armor": 16,
   "shield": 0.18,
   "interact_speed": 0.16,
   "dodge_cooldown": 0.12,
   "medkit": 0.03,
   "pickup": 0.15000000000000002
  },
  "branch_points": [
   {
    "branch": "Machines",
    "points": 47
   },
   {
    "branch": "Energy",
    "points": 6
   },
   {
    "branch": "Fortification",
    "points": 46
   }
  ]
 },
 {
  "class": "warden",
  "budget": 1,
  "allocation": {
   "guard_iron_guard": 1
  },
  "effects": {
   "armor": 2
  },
  "branch_points": [
   {
    "branch": "Guard",
    "points": 1
   },
   {
    "branch": "Retribution",
    "points": 0
   },
   {
    "branch": "Sanctuary",
    "points": 0
   }
  ]
 },
 {
  "class": "warden",
  "budget": 25,
  "allocation": {
   "guard_iron_guard": 5,
   "guard_stalwart": 5,
   "guard_deep_aegis": 5,
   "guard_aegis_vigil": 4,
   "guard_defensive_works": 4,
   "guard_layered_aegis": 2
  },
  "effects": {
   "armor": 10,
   "hp": 0.1,
   "shield": 0.14,
   "class_cooldown": 0.12,
   "structure_hp": 0.2
  },
  "branch_points": [
   {
    "branch": "Guard",
    "points": 25
   },
   {
    "branch": "Retribution",
    "points": 0
   },
   {
    "branch": "Sanctuary",
    "points": 0
   }
  ]
 },
 {
  "class": "warden",
  "budget": 50,
  "allocation": {
   "guard_iron_guard": 5,
   "guard_stalwart": 5,
   "guard_deep_aegis": 5,
   "guard_aegis_vigil": 4,
   "guard_defensive_works": 4,
   "guard_layered_aegis": 4,
   "sanctuary_hallowed_ground": 5,
   "sanctuary_sanctuary_rhythm": 5,
   "guard_winter_wall": 4,
   "guard_tempered_guard": 3,
   "guard_winter_vigil": 3,
   "guard_unbroken": 3
  },
  "effects": {
   "armor": 16,
   "hp": 0.16,
   "shield": 0.18,
   "class_cooldown": 0.12,
   "structure_hp": 0.2,
   "spell_damage_by_id": {
    "frost": 0.16,
    "ground": 0.2
   },
   "spell_cooldown_by_id": {
    "frost": 0.09,
    "ground": 0.1
   }
  },
  "branch_points": [
   {
    "branch": "Guard",
    "points": 40
   },
   {
    "branch": "Retribution",
    "points": 0
   },
   {
    "branch": "Sanctuary",
    "points": 10
   }
  ]
 },
 {
  "class": "warden",
  "budget": 99,
  "allocation": {
   "guard_iron_guard": 5,
   "guard_stalwart": 5,
   "guard_deep_aegis": 5,
   "guard_aegis_vigil": 4,
   "guard_defensive_works": 4,
   "guard_layered_aegis": 4,
   "sanctuary_hallowed_ground": 5,
   "sanctuary_sanctuary_rhythm": 5,
   "guard_winter_wall": 4,
   "guard_tempered_guard": 3,
   "guard_winter_vigil": 3,
   "guard_unbroken": 3,
   "sanctuary_healing_stores": 5,
   "sanctuary_pilgrim_s_reach": 4,
   "sanctuary_mending_works": 4,
   "guard_resolute_step": 3,
   "guard_constant_vigil": 2,
   "wisp": 1,
   "sanctuary_guardian_wisp": 4,
   "sanctuary_quiet_focus": 4,
   "sanctuary_sheltered_works": 3,
   "ember": 1,
   "sanctuary_vigil_flame": 3,
   "sanctuary_vigil_rhythm": 3,
   "sanctuary_sacred_routine": 3,
   "sanctuary_pilgrim_s_pace": 2,
   "retribution_firm_hand": 5,
   "retribution_judgment_lance": 2
  },
  "effects": {
   "armor": 16,
   "hp": 0.16,
   "shield": 0.18,
   "class_cooldown": 0.18,
   "structure_hp": 0.29000000000000004,
   "spell_damage_by_id": {
    "frost": 0.16,
    "lance": 0.08,
    "ground": 0.2,
    "wisp": 0.2,
    "ember": 0.15000000000000002
   },
   "spell_cooldown_by_id": {
    "frost": 0.09,
    "ground": 0.1,
    "ember": 0.09
   },
   "dodge_cooldown": 0.12,
   "basic_damage": 0.1,
   "medkit": 0.05,
   "pickup": 0.2,
   "repair": 0.2,
   "cooldown": 0.04,
   "interact_speed": 0.15000000000000002,
   "speed": 0.04
  },
  "branch_points": [
   {
    "branch": "Guard",
    "points": 45
   },
   {
    "branch": "Retribution",
    "points": 7
   },
   {
    "branch": "Sanctuary",
    "points": 47
   }
  ]
 },
 {
  "class": "arcanist",
  "budget": 1,
  "allocation": {
   "fire_kindled_ember": 1
  },
  "effects": {
   "spell_damage_by_id": {
    "ember": 0.04
   }
  },
  "branch_points": [
   {
    "branch": "Fire",
    "points": 1
   },
   {
    "branch": "Frost",
    "points": 0
   },
   {
    "branch": "Arcane",
    "points": 0
   }
  ]
 },
 {
  "class": "arcanist",
  "budget": 25,
  "allocation": {
   "fire_kindled_ember": 5,
   "fire_ember_rhythm": 5,
   "fire_wand_practice": 5,
   "fire_heat_hardened": 4,
   "chain": 1,
   "fire_conductive_sparks": 4,
   "fire_focused_flame": 1
  },
  "effects": {
   "spell_damage_by_id": {
    "ember": 0.2,
    "chain": 0.16
   },
   "spell_cooldown_by_id": {
    "ember": 0.1
   },
   "basic_damage": 0.1,
   "hp": 0.08,
   "spell_damage": 0.02
  },
  "branch_points": [
   {
    "branch": "Fire",
    "points": 25
   },
   {
    "branch": "Frost",
    "points": 0
   },
   {
    "branch": "Arcane",
    "points": 0
   }
  ]
 },
 {
  "class": "arcanist",
  "budget": 50,
  "allocation": {
   "fire_kindled_ember": 5,
   "fire_ember_rhythm": 5,
   "fire_wand_practice": 5,
   "fire_heat_hardened": 4,
   "chain": 1,
   "fire_conductive_sparks": 4,
   "fire_focused_flame": 4,
   "frost_deep_frost": 5,
   "frost_frost_rhythm": 4,
   "fire_spark_rhythm": 4,
   "fire_ember_salves": 3,
   "fire_furnace_works": 3,
   "fire_deep_combustion": 3
  },
  "effects": {
   "spell_damage_by_id": {
    "ember": 0.23,
    "chain": 0.16,
    "frost": 0.2
   },
   "spell_cooldown_by_id": {
    "ember": 0.1,
    "chain": 0.08,
    "frost": 0.08
   },
   "basic_damage": 0.1,
   "hp": 0.08,
   "spell_damage": 0.08,
   "medkit": 0.03,
   "structure_damage": 0.15000000000000002
  },
  "branch_points": [
   {
    "branch": "Fire",
    "points": 41
   },
   {
    "branch": "Frost",
    "points": 9
   },
   {
    "branch": "Arcane",
    "points": 0
   }
  ]
 },
 {
  "class": "arcanist",
  "budget": 99,
  "allocation": {
   "fire_kindled_ember": 5,
   "fire_ember_rhythm": 5,
   "fire_wand_practice": 5,
   "fire_heat_hardened": 4,
   "chain": 1,
   "fire_conductive_sparks": 4,
   "fire_focused_flame": 4,
   "frost_deep_frost": 5,
   "frost_frost_rhythm": 5,
   "fire_spark_rhythm": 4,
   "fire_ember_salves": 3,
   "fire_furnace_works": 3,
   "fire_deep_combustion": 3,
   "frost_crystalline_shield": 5,
   "lance": 1,
   "frost_glacial_lance": 4,
   "fire_pulse_ignition": 3,
   "fire_blazing_focus": 2,
   "frost_rime_armor": 4,
   "ground": 1,
   "frost_frozen_ground": 4,
   "frost_lance_rhythm": 4,
   "frost_ground_rhythm": 3,
   "frost_winter_endurance": 3,
   "frost_gliding_escape": 3,
   "frost_cold_repairs": 3,
   "frost_perfected_crystal": 2,
   "arcane_arcane_channels": 5,
   "arcane_empowered_wisp": 1
  },
  "effects": {
   "spell_damage_by_id": {
    "ember": 0.23,
    "chain": 0.16,
    "frost": 0.2,
    "lance": 0.16,
    "ground": 0.16,
    "wisp": 0.04
   },
   "spell_cooldown_by_id": {
    "ember": 0.1,
    "chain": 0.08,
    "frost": 0.1,
    "lance": 0.08,
    "ground": 0.09
   },
   "basic_damage": 0.1,
   "hp": 0.14,
   "spell_damage": 0.12,
   "medkit": 0.03,
   "structure_damage": 0.15000000000000002,
   "class_cooldown": 0.06,
   "shield": 0.19,
   "armor": 8,
   "dodge_cooldown": 0.12,
   "repair": 0.15000000000000002,
   "cooldown": 0.05
  },
  "branch_points": [
   {
    "branch": "Fire",
    "points": 46
   },
   {
    "branch": "Frost",
    "points": 47
   },
   {
    "branch": "Arcane",
    "points": 6
   }
  ]
 }
]
const PATH := "user://nightfall_class_talents_fixture.json"
var checks := 0
var failures := 0
func check(ok: bool, description: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(description)
func cleanup() -> void:
 for suffix in ["", ".bak", ".tmp"]:
  if FileAccess.file_exists(PATH+suffix):
   DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH+suffix))
func _initialize() -> void:
 cleanup()
 var p = Profile.new(PATH)
 check(p.save() and p.valid(p.data),"Fresh v6 profile valid")
 check(p.data.training_style=="ranged","Fresh class focus matches its starter pistol")
 var run=load("res://run.gd").new(77)
 run.configure(1,p.stats());run.spawn_enemy()
 var victim: Dictionary=run.enemies.back()
 run.damage_enemy(victim,victim.hp+100,run.player)
 var initial_attempt: Dictionary=p.start_attempt(1)
 p.finish_attempt(initial_attempt.id,run.result())
 check(p.combat_experience("scavenger").ranged>0 and p.combat_experience("scavenger").attack==0,"Default pistol damage advances the Ranged equipment gate")
 p.data.last_result={}
 for id in Skills.STARTERS:
  check(p.class_combat_level(id)==1 and p.skill_points(id)==1,"Each class starts at1 with1 point")
  var capacity := 0
  var ranks := {}
  for node in Skills.nodes(id):
   capacity += node.max_rank
   ranks[node.id] = node.max_rank
  check(capacity==Skills.DESIGN.classes[id].capacity,"Class tree has deliberate excess capacity")
  for node in Skills.nodes(id):
   check(Skills.requirement(id,node.id,ranks).is_empty(),"Every node has reachable gates: "+id+" "+node.id)
  var bonuses := Skills.bonuses(id,ranks)
  for stat in Skills.CAPS:
   check(bonuses[stat] <= Skills.CAPS[stat]+0.000001,"Talent stat cap "+id+" "+stat)
 check(p.rank_talent("scavenger","precision_sure_shot") and p.skill_points("scavenger")==0,"Spend first point")
 check(p.skill_points("engineer")==1 and not p.rank_talent("engineer","precision_sure_shot"),"Locked class cannot spend another class budget")
 check(not p.rank_talent("scavenger","precision_quick_blades"),"Tier and rank prerequisites enforced")
 var previous: Dictionary=p.data.duplicate(true)
 p.path="user://missing-class-talents-dir/test.json"
 check(not p.reset_talents("scavenger") and p.data==previous,"Failed refund save rolls back")
 p.path=PATH
 check(p.reset_talents("scavenger") and p.skill_points("scavenger")==1,"Free class refund restores point")
 for stat in Training.STATS:
  p.combat_experience("scavenger")[stat]=Training.MAX_XP
 check(p.class_combat_level("scavenger")==99 and p.skill_points("scavenger")==99,"Class99 has exactly99 lifetime points")
 var baseline: Dictionary=Profile.new().stats()
 var target: Dictionary={}
 for example in EXAMPLES:
  check(Skills.spent(example["class"],example.allocation)==example.budget and Skills.valid(example["class"],example.allocation),"Authored route is legal at budget "+str(example.budget)+" "+example["class"])
  if example["class"]=="scavenger" and example.budget==99:target=example.allocation
 for pass_index in 99:
  var changed:=false
  for id in target:
   if p.talent_ranks("scavenger").get(id,0)<target[id] and Skills.requirement("scavenger",id,p.talent_ranks("scavenger")).is_empty():
    check(p.rank_talent("scavenger",id),"Authored99-point route spend "+id)
    changed=true
  if not changed:break
 check(p.skill_points("scavenger")==0 and Skills.spent("scavenger",p.talent_ranks("scavenger"))==99,"Can allocate every earned point")
 check(not p.rank_talent("scavenger","gravity"),"Cannot spend a100th point")
 var stats: Dictionary=p.stats()
 check(stats.talent_effects.basic_damage>0 and stats.armor>baseline.armor,"Owned talents reach actual mission stats")
 check(stats.speed<=1.15 and stats.pickup<=1.5 and stats.cooldown<=0.15,"Combined permanent stat caps preserved")
 var restored = Profile.new(PATH)
 check(restored.load_save() and restored.data==p.data,"All99 ranks persist through disk")
 check(p.reset_talents("scavenger") and p.skill_points("scavenger")==99,"Respec never exceeds99")
 p.data.missions["4"]=["clear"]
 check(p.select_class("engineer") and p.class_combat_level("engineer")==1 and p.stats().training_bonuses==Training.bonuses(Training.fresh()),"Changing class does not inherit trained levels")
 check(p.set_training_style("arcane") and p.select_class("scavenger") and p.data.training_style=="ranged","Training focus independently retained")
 check(p.select_class("engineer") and p.data.training_style=="arcane","Engineer focus restored")
 var attempt: Dictionary=p.start_attempt(1)
 var outcome := {"victory":false,"combat_xp":Training.fresh()}
 outcome.combat_xp.magic=Training.threshold(4)
 var receipt: Dictionary=p.finish_attempt(attempt.id,outcome)
 check(not receipt.is_empty() and p.combat_experience("engineer").magic==Training.threshold(4) and p.combat_experience("scavenger").magic==Training.MAX_XP,"Banking applies only to attempt class")
 check(p.data.settings.damage_numbers and p.data.settings.health_bars and p.set_setting("damage_numbers",false) and not p.set_setting("health_bars",2),"Display toggles validate booleans")
 var legacy: Dictionary=p.data.duplicate(true)
 legacy.version=5
 legacy.erase("class_combat")
 legacy.erase("talent_migration_notice")
 legacy.training_style="accurate"
 legacy.combat_xp=Training.fresh()
 var expected := {}
 var index := 0
 for stat in Training.STATS:
  var level: int=[1,10,20,40,98,99][index]
  var xp: float=Training.legacy_threshold(level)
  if level<99:
   xp += (Training.legacy_threshold(level+1)-xp)*0.42
  legacy.combat_xp[stat]=xp
  expected[stat]=level
  index+=1
 legacy.skill_unlocks.engineer=Skills.BRANCHES.engineer.duplicate()
 legacy.skill_unlocks.scavenger=["wisp"]
 legacy.settings.erase("damage_numbers")
 legacy.settings.erase("health_bars")
 var file=FileAccess.open(PATH,FileAccess.WRITE)
 file.store_string(JSON.stringify(legacy));file.close()
 restored=Profile.new(PATH)
 check(restored.load_save(),"Version5 global save migrates")
 check(restored.data.training_style=="accurate","Explicit legacy Accurate focus is preserved")
 for stat in Training.STATS:
  check(Training.level(restored.combat_experience("engineer")[stat])==expected[stat],"Migration retains level "+stat)
 check(restored.class_combat_level("scavenger")==1 and restored.combat_experience("scavenger")==Training.fresh(),"Other classes receive no duplicated global XP")
 check(restored.ability_pool("engineer").size()==8 and restored.ability_pool("scavenger").has("wisp"),"Legacy spell builds remain equipped through inherited node exemptions")
 check(restored.data.class_combat.engineer.legacy_entitlement==9 and not restored.data.talent_migration_notice.is_empty(),"Old9-point cost becomes5 ranks plus4 spendable retained points")
 check(restored.data.settings.damage_numbers and restored.data.settings.health_bars,"New visual settings migrate true")
 check(restored.save(),"Migrated save writes")
 var twice=Profile.new(PATH)
 check(twice.load_save() and twice.data==restored.data,"Migration idempotent, no repeat XP or refunds")
 var invalid: Dictionary=twice.data.duplicate(true)
 invalid.class_combat.engineer.talent_ranks.machines_calibrated_turrets=6
 check(not twice.valid(invalid),"Corrupt rank6 rejected")
 invalid=twice.data.duplicate(true)
 invalid.class_combat.engineer.xp.magic=NAN
 check(not twice.valid(invalid),"Nonfinite class XP rejected")
 var draft: Dictionary=Profile.new(PATH).fresh()
 draft.erase("talent_revision")
 for stat in Training.STATS:draft.class_combat.scavenger.xp[stat]=Training.MAX_XP
 draft.class_combat.scavenger.talent_ranks={"hp_1":5}
 file=FileAccess.open(PATH,FileAccess.WRITE);file.store_string(JSON.stringify(draft));file.close()
 var migrated=Profile.new(PATH)
 check(migrated.load_save() and migrated.talent_ranks("scavenger").is_empty() and migrated.skill_points("scavenger")==99,"Unreleased generic draft receives an explicit full refund")
 check(migrated.class_combat_level("scavenger")==99 and migrated.data.talent_migration_notice.contains("5 generic"),"Draft refund preserves trained levels and explains change")
 cleanup()
 print("Class talents: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
