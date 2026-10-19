extends RefCounted
## Shared ranked talent definitions used by spending and read-only preview.
const Combat = preload("res://combat_content.gd")
const STARTERS := {
 "scavenger": ["ember", "frost", "chain"], "engineer": ["ember", "chain", "wisp"],
 "warden": ["frost", "lance", "ground"], "arcanist": ["ember", "frost", "wisp"]}
const BRANCHES := {
 "scavenger": ["wisp", "blades", "lance", "ground", "gravity"],
 "engineer": ["frost", "lance", "ground", "blades", "gravity"],
 "warden": ["ember", "wisp", "blades", "chain", "gravity"],
 "arcanist": ["chain", "lance", "blades", "ground", "gravity"]}
const COSTS := [1,1,2,2,3]
const POINT_CAP := 99
const GATES := [0,15,35,60]
const ROWS := [0,1,1,2,2,3,4,4,5,5,6,6]
const POSITIONS := [Vector2(180,80),Vector2(88,240),Vector2(272,226),Vector2(62,416),Vector2(298,400),Vector2(180,576),Vector2(102,750),Vector2(272,734),Vector2(65,925),Vector2(297,910),Vector2(111,1094),Vector2(258,1080)]
const DESIGN = {
 "caps": {
  "basic_damage": 0.2,
  "spell_damage": 0.15,
  "spell_damage_by_id": 0.25,
  "combined_spell_damage": 0.35,
  "structure_damage": 0.25,
  "structure_hp": 0.3,
  "repair": 0.3,
  "dodge_cooldown": 0.2,
  "class_cooldown": 0.2,
  "shield": 0.2,
  "interact_speed": 0.25,
  "spell_cooldown_by_id": 0.15,
  "hp": 0.2,
  "armor": 18,
  "speed": 0.1,
  "pickup": 0.3,
  "cooldown": 0.08,
  "medkit": 0.05,
  "capacity": 1,
  "secure": 1,
  "power": 0
 },
 "links": [
  [],
  [
   0
  ],
  [
   0
  ],
  [
   1
  ],
  [
   2
  ],
  [
   3,
   4
  ],
  [
   5
  ],
  [
   5
  ],
  [
   6
  ],
  [
   7
  ],
  [
   8
  ],
  [
   9
  ]
 ],
 "class_spend_gates_by_index": [
  0,
  0,
  0,
  15,
  15,
  15,
  35,
  35,
  35,
  35,
  60,
  60
 ],
 "classes": {
  "scavenger": {
   "branches": [
    {
     "id": "precision",
     "name": "Precision",
     "description": "Reliable weapon hits and precise spell support"
    },
    {
     "id": "scavenge",
     "name": "Scavenge",
     "description": "Reach supplies and improve the supplies you carry"
    },
    {
     "id": "mobility",
     "name": "Mobility",
     "description": "Shorter escape cycles and room to keep moving"
    }
   ],
   "nodes": [
    {
     "id": "precision_sure_shot",
     "name": "Sure Shot",
     "branch": 0,
     "index": 0,
     "max_rank": 5,
     "effects": {
      "basic_damage": 0.02
     },
     "spell": ""
    },
    {
     "id": "precision_spectral_edge",
     "name": "Spectral Edge",
     "branch": 0,
     "index": 1,
     "max_rank": 5,
     "effects": {
      "spell_damage_by_id": {
       "blades": 0.04
      }
     },
     "spell": ""
    },
    {
     "id": "precision_needlepoint",
     "name": "Needlepoint",
     "branch": 0,
     "index": 2,
     "max_rank": 5,
     "effects": {
      "spell_damage_by_id": {
       "lance": 0.04
      }
     },
     "spell": ""
    },
    {
     "id": "precision_quick_blades",
     "name": "Quick Blades",
     "branch": 0,
     "index": 3,
     "max_rank": 4,
     "effects": {
      "spell_cooldown_by_id": {
       "blades": 0.02
      }
     },
     "spell": ""
    },
    {
     "id": "precision_lance_drill",
     "name": "Lance Drill",
     "branch": 0,
     "index": 4,
     "max_rank": 4,
     "effects": {
      "spell_cooldown_by_id": {
       "lance": 0.02
      }
     },
     "spell": ""
    },
    {
     "id": "precision_measured_fire",
     "name": "Measured Fire",
     "branch": 0,
     "index": 5,
     "max_rank": 4,
     "effects": {
      "basic_damage": 0.015
     },
     "spell": ""
    },
    {
     "id": "precision_phase_rhythm",
     "name": "Phase Rhythm",
     "branch": 0,
     "index": 6,
     "max_rank": 4,
     "effects": {
      "class_cooldown": 0.02
     },
     "spell": ""
    },
    {
     "id": "precision_braced_aim",
     "name": "Braced Aim",
     "branch": 0,
     "index": 7,
     "max_rank": 3,
     "effects": {
      "armor": 2
     },
     "spell": ""
    },
    {
     "id": "precision_conductive_shot",
     "name": "Conductive Shot",
     "branch": 0,
     "index": 8,
     "max_rank": 3,
     "effects": {
      "spell_damage_by_id": {
       "chain": 0.05
      }
     },
     "spell": ""
    },
    {
     "id": "precision_quick_relay",
     "name": "Quick Relay",
     "branch": 0,
     "index": 9,
     "max_rank": 3,
     "effects": {
      "spell_cooldown_by_id": {
       "chain": 0.03
      }
     },
     "spell": ""
    },
    {
     "id": "precision_storm_followthrough",
     "name": "Storm Followthrough",
     "branch": 0,
     "index": 10,
     "max_rank": 3,
     "effects": {
      "spell_damage_by_id": {
       "chain": 0.03
      }
     },
     "spell": ""
    },
    {
     "id": "precision_deadeye",
     "name": "Deadeye",
     "branch": 0,
     "index": 11,
     "max_rank": 2,
     "effects": {
      "basic_damage": 0.02
     },
     "spell": ""
    },
    {
     "id": "scavenge_trail_finder",
     "name": "Trail Finder",
     "branch": 1,
     "index": 0,
     "max_rank": 5,
     "effects": {
      "pickup": 0.04
     },
     "spell": ""
    },
    {
     "id": "scavenge_practiced_hands",
     "name": "Practiced Hands",
     "branch": 1,
     "index": 1,
     "max_rank": 5,
     "effects": {
      "interact_speed": 0.03
     },
     "spell": ""
    },
    {
     "id": "scavenge_hardy_rations",
     "name": "Hardy Rations",
     "branch": 1,
     "index": 2,
     "max_rank": 5,
     "effects": {
      "hp": 0.02
     },
     "spell": ""
    },
    {
     "id": "scavenge_field_medicine",
     "name": "Field Medicine",
     "branch": 1,
     "index": 3,
     "max_rank": 4,
     "effects": {
      "medkit": 0.01
     },
     "spell": ""
    },
    {
     "id": "scavenge_watchful_lantern",
     "name": "Watchful Lantern",
     "branch": 1,
     "index": 4,
     "max_rank": 4,
     "effects": {
      "spell_damage_by_id": {
       "wisp": 0.05
      }
     },
     "spell": ""
    },
    {
     "id": "scavenge_claim_the_ground",
     "name": "Claim the Ground",
     "branch": 1,
     "index": 5,
     "max_rank": 4,
     "effects": {
      "spell_damage_by_id": {
       "ground": 0.04
      }
     },
     "spell": ""
    },
    {
     "id": "scavenge_camp_routine",
     "name": "Camp Routine",
     "branch": 1,
     "index": 6,
     "max_rank": 4,
     "effects": {
      "spell_cooldown_by_id": {
       "ground": 0.02
      }
     },
     "spell": ""
    },
    {
     "id": "scavenge_far_collector",
     "name": "Far Collector",
     "branch": 1,
     "index": 7,
     "max_rank": 3,
     "effects": {
      "pickup": 0.02
     },
     "spell": ""
    },
    {
     "id": "scavenge_expanded_satchel",
     "name": "Expanded Satchel",
     "branch": 1,
     "index": 8,
     "max_rank": 1,
     "effects": {
      "capacity": 1
     },
     "spell": ""
    },
    {
     "id": "scavenge_hidden_compartment",
     "name": "Hidden Compartment",
     "branch": 1,
     "index": 9,
     "max_rank": 1,
     "effects": {
      "secure": 1
     },
     "spell": ""
    },
    {
     "id": "scavenge_shrine_familiarity",
     "name": "Shrine Familiarity",
     "branch": 1,
     "index": 10,
     "max_rank": 3,
     "effects": {
      "interact_speed": 0.02
     },
     "spell": ""
    },
    {
     "id": "scavenge_long_haul",
     "name": "Long Haul",
     "branch": 1,
     "index": 11,
     "max_rank": 2,
     "effects": {
      "hp": 0.02
     },
     "spell": ""
    },
    {
     "id": "mobility_light_foot",
     "name": "Light Foot",
     "branch": 2,
     "index": 0,
     "max_rank": 5,
     "effects": {
      "speed": 0.01
     },
     "spell": ""
    },
    {
     "id": "mobility_rolling_escape",
     "name": "Rolling Escape",
     "branch": 2,
     "index": 1,
     "max_rank": 5,
     "effects": {
      "dodge_cooldown": 0.02
     },
     "spell": ""
    },
    {
     "id": "mobility_phase_practice",
     "name": "Phase Practice",
     "branch": 2,
     "index": 2,
     "max_rank": 5,
     "effects": {
      "class_cooldown": 0.02
     },
     "spell": ""
    },
    {
     "id": "mobility_clearing_knot",
     "name": "Clearing Knot",
     "branch": 2,
     "index": 3,
     "max_rank": 4,
     "effects": {
      "spell_damage_by_id": {
       "gravity": 0.04
      }
     },
     "spell": ""
    },
    {
     "id": "mobility_knot_rhythm",
     "name": "Knot Rhythm",
     "branch": 2,
     "index": 4,
     "max_rank": 4,
     "effects": {
      "spell_cooldown_by_id": {
       "gravity": 0.02
      }
     },
     "spell": ""
    },
    {
     "id": "mobility_winter_shelter",
     "name": "Winter Shelter",
     "branch": 2,
     "index": 5,
     "max_rank": 4,
     "effects": {
      "shield": 0.025
     },
     "spell": ""
    },
    {
     "id": "mobility_cold_wake",
     "name": "Cold Wake",
     "branch": 2,
     "index": 6,
     "max_rank": 4,
     "effects": {
      "spell_damage_by_id": {
       "frost": 0.04
      }
     },
     "spell": ""
    },
    {
     "id": "mobility_winter_rhythm",
     "name": "Winter Rhythm",
     "branch": 2,
     "index": 7,
     "max_rank": 3,
     "effects": {
      "spell_cooldown_by_id": {
       "frost": 0.03
      }
     },
     "spell": ""
    },
    {
     "id": "mobility_second_wind",
     "name": "Second Wind",
     "branch": 2,
     "index": 8,
     "max_rank": 3,
     "effects": {
      "dodge_cooldown": 0.025
     },
     "spell": ""
    },
    {
     "id": "mobility_unburdened",
     "name": "Unburdened",
     "branch": 2,
     "index": 9,
     "max_rank": 3,
     "effects": {
      "speed": 0.01
     },
     "spell": ""
    },
    {
     "id": "mobility_covering_turret",
     "name": "Covering Turret",
     "branch": 2,
     "index": 10,
     "max_rank": 3,
     "effects": {
      "structure_damage": 0.04
     },
     "spell": ""
    },
    {
     "id": "mobility_emergency_dressings",
     "name": "Emergency Dressings",
     "branch": 2,
     "index": 11,
     "max_rank": 2,
     "effects": {
      "medkit": 0.005
     },
     "spell": ""
    }
   ],
   "spell_unlocks": [
    {
     "id": "blades",
     "branch": 0,
     "linked_index": 1,
     "max_rank": 1,
     "note": "Place spell before its specialization node; spell purchase needs only prior path, not the specialization node itself."
    },
    {
     "id": "lance",
     "branch": 0,
     "linked_index": 2,
     "max_rank": 1,
     "note": "Place spell before its specialization node; spell purchase needs only prior path, not the specialization node itself."
    },
    {
     "id": "ground",
     "branch": 1,
     "linked_index": 5,
     "max_rank": 1,
     "note": "Place spell before its specialization node; spell purchase needs only prior path, not the specialization node itself."
    },
    {
     "id": "wisp",
     "branch": 1,
     "linked_index": 4,
     "max_rank": 1,
     "note": "Place spell before its specialization node; spell purchase needs only prior path, not the specialization node itself."
    },
    {
     "id": "gravity",
     "branch": 2,
     "linked_index": 3,
     "max_rank": 1,
     "note": "Place spell before its specialization node; spell purchase needs only prior path, not the specialization node itself."
    }
   ],
   "capacity": 136
  },
  "engineer": {
   "branches": [
    {
     "id": "machines",
     "name": "Machines",
     "description": "Stronger emplacements, repairs and supporting steel"
    },
    {
     "id": "energy",
     "name": "Energy",
     "description": "Electrical spell support and faster class cycles"
    },
    {
     "id": "fortification",
     "name": "Fortification",
     "description": "Hold a worksite with health, cover and supplies"
    }
   ],
   "nodes": [
    {
     "id": "machines_calibrated_turrets",
     "name": "Calibrated Turrets",
     "branch": 0,
     "index": 0,
     "max_rank": 5,
     "effects": {
      "structure_damage": 0.03
     },
     "spell": ""
    },
    {
     "id": "machines_reinforced_chassis",
     "name": "Reinforced Chassis",
     "branch": 0,
     "index": 1,
     "max_rank": 5,
     "effects": {
      "structure_hp": 0.04
     },
     "spell": ""
    },
    {
     "id": "machines_sidearm_drills",
     "name": "Sidearm Drills",
     "branch": 0,
     "index": 2,
     "max_rank": 5,
     "effects": {
      "basic_damage": 0.02
     },
     "spell": ""
    },
    {
     "id": "machines_service_tools",
     "name": "Service Tools",
     "branch": 0,
     "index": 3,
     "max_rank": 4,
     "effects": {
      "repair": 0.04
     },
     "spell": ""
    },
    {
     "id": "machines_spectral_cutters",
     "name": "Spectral Cutters",
     "branch": 0,
     "index": 4,
     "max_rank": 4,
     "effects": {
      "spell_damage_by_id": {
       "blades": 0.04
      }
     },
     "spell": ""
    },
    {
     "id": "machines_drive_calibration",
     "name": "Drive Calibration",
     "branch": 0,
     "index": 5,
     "max_rank": 4,
     "effects": {
      "structure_damage": 0.015
     },
     "spell": ""
    },
    {
     "id": "machines_piledriver",
     "name": "Piledriver",
     "branch": 0,
     "index": 6,
     "max_rank": 4,
     "effects": {
      "spell_damage_by_id": {
       "lance": 0.04
      }
     },
     "spell": ""
    },
    {
     "id": "machines_redundant_bracing",
     "name": "Redundant Bracing",
     "branch": 0,
     "index": 7,
     "max_rank": 3,
     "effects": {
      "structure_hp": 0.03
     },
     "spell": ""
    },
    {
     "id": "machines_cutter_timing",
     "name": "Cutter Timing",
     "branch": 0,
     "index": 8,
     "max_rank": 3,
     "effects": {
      "spell_cooldown_by_id": {
       "blades": 0.03
      }
     },
     "spell": ""
    },
    {
     "id": "machines_piston_timing",
     "name": "Piston Timing",
     "branch": 0,
     "index": 9,
     "max_rank": 3,
     "effects": {
      "spell_cooldown_by_id": {
       "lance": 0.03
      }
     },
     "spell": ""
    },
    {
     "id": "machines_precision_repairs",
     "name": "Precision Repairs",
     "branch": 0,
     "index": 10,
     "max_rank": 3,
     "effects": {
      "repair": 0.04
     },
     "spell": ""
    },
    {
     "id": "machines_siege_calibration",
     "name": "Siege Calibration",
     "branch": 0,
     "index": 11,
     "max_rank": 2,
     "effects": {
      "structure_damage": 0.02
     },
     "spell": ""
    },
    {
     "id": "energy_swarm_cycling",
     "name": "Swarm Cycling",
     "branch": 1,
     "index": 0,
     "max_rank": 5,
     "effects": {
      "class_cooldown": 0.02
     },
     "spell": ""
    },
    {
     "id": "energy_charged_relay",
     "name": "Charged Relay",
     "branch": 1,
     "index": 1,
     "max_rank": 5,
     "effects": {
      "spell_damage_by_id": {
       "chain": 0.04
      }
     },
     "spell": ""
    },
    {
     "id": "energy_cryogenic_coil",
     "name": "Cryogenic Coil",
     "branch": 1,
     "index": 2,
     "max_rank": 5,
     "effects": {
      "spell_damage_by_id": {
       "frost": 0.04
      }
     },
     "spell": ""
    },
    {
     "id": "energy_relay_timing",
     "name": "Relay Timing",
     "branch": 1,
     "index": 3,
     "max_rank": 4,
     "effects": {
      "spell_cooldown_by_id": {
       "chain": 0.02
      }
     },
     "spell": ""
    },
    {
     "id": "energy_coolant_timing",
     "name": "Coolant Timing",
     "branch": 1,
     "index": 4,
     "max_rank": 4,
     "effects": {
      "spell_cooldown_by_id": {
       "frost": 0.02
      }
     },
     "spell": ""
    },
    {
     "id": "energy_arcane_dynamo",
     "name": "Arcane Dynamo",
     "branch": 1,
     "index": 5,
     "max_rank": 4,
     "effects": {
      "spell_damage": 0.02
     },
     "spell": ""
    },
    {
     "id": "energy_efficient_channels",
     "name": "Efficient Channels",
     "branch": 1,
     "index": 6,
     "max_rank": 4,
     "effects": {
      "cooldown": 0.01
     },
     "spell": ""
    },
    {
     "id": "energy_auxiliary_swarm",
     "name": "Auxiliary Swarm",
     "branch": 1,
     "index": 7,
     "max_rank": 3,
     "effects": {
      "class_cooldown": 0.02
     },
     "spell": ""
    },
    {
     "id": "energy_gravitic_motor",
     "name": "Gravitic Motor",
     "branch": 1,
     "index": 8,
     "max_rank": 3,
     "effects": {
      "spell_damage_by_id": {
       "gravity": 0.05
      }
     },
     "spell": ""
    },
    {
     "id": "energy_motor_timing",
     "name": "Motor Timing",
     "branch": 1,
     "index": 9,
     "max_rank": 3,
     "effects": {
      "spell_cooldown_by_id": {
       "gravity": 0.03
      }
     },
     "spell": ""
    },
    {
     "id": "energy_powered_sidearm",
     "name": "Powered Sidearm",
     "branch": 1,
     "index": 10,
     "max_rank": 3,
     "effects": {
      "basic_damage": 0.02
     },
     "spell": ""
    },
    {
     "id": "energy_overcharged_core",
     "name": "Overcharged Core",
     "branch": 1,
     "index": 11,
     "max_rank": 2,
     "effects": {
      "spell_damage": 0.02
     },
     "spell": ""
    },
    {
     "id": "fortification_worksite_resolve",
     "name": "Worksite Resolve",
     "branch": 2,
     "index": 0,
     "max_rank": 5,
     "effects": {
      "hp": 0.02
     },
     "spell": ""
    },
    {
     "id": "fortification_plate_harness",
     "name": "Plate Harness",
     "branch": 2,
     "index": 1,
     "max_rank": 5,
     "effects": {
      "armor": 2
     },
     "spell": ""
    },
    {
     "id": "fortification_shield_lattice",
     "name": "Shield Lattice",
     "branch": 2,
     "index": 2,
     "max_rank": 5,
     "effects": {
      "shield": 0.02
     },
     "spell": ""
    },
    {
     "id": "fortification_rapid_setup",
     "name": "Rapid Setup",
     "branch": 2,
     "index": 3,
     "max_rank": 4,
     "effects": {
      "interact_speed": 0.04
     },
     "spell": ""
    },
    {
     "id": "fortification_anchored_ground",
     "name": "Anchored Ground",
     "branch": 2,
     "index": 4,
     "max_rank": 4,
     "effects": {
      "spell_damage_by_id": {
       "ground": 0.04
      }
     },
     "spell": ""
    },
    {
     "id": "fortification_ground_cycling",
     "name": "Ground Cycling",
     "branch": 2,
     "index": 5,
     "max_rank": 4,
     "effects": {
      "spell_cooldown_by_id": {
       "ground": 0.02
      }
     },
     "spell": ""
    },
    {
     "id": "fortification_exit_route",
     "name": "Exit Route",
     "branch": 2,
     "index": 6,
     "max_rank": 4,
     "effects": {
      "dodge_cooldown": 0.03
     },
     "spell": ""
    },
    {
     "id": "fortification_enduring_crew",
     "name": "Enduring Crew",
     "branch": 2,
     "index": 7,
     "max_rank": 3,
     "effects": {
      "hp": 0.02
     },
     "spell": ""
    },
    {
     "id": "fortification_riveted_plates",
     "name": "Riveted Plates",
     "branch": 2,
     "index": 8,
     "max_rank": 3,
     "effects": {
      "armor": 2
     },
     "spell": ""
    },
    {
     "id": "fortification_field_triage",
     "name": "Field Triage",
     "branch": 2,
     "index": 9,
     "max_rank": 3,
     "effects": {
      "medkit": 0.01
     },
     "spell": ""
    },
    {
     "id": "fortification_supply_sweep",
     "name": "Supply Sweep",
     "branch": 2,
     "index": 10,
     "max_rank": 3,
     "effects": {
      "pickup": 0.05
     },
     "spell": ""
    },
    {
     "id": "fortification_layered_lattice",
     "name": "Layered Lattice",
     "branch": 2,
     "index": 11,
     "max_rank": 2,
     "effects": {
      "shield": 0.04
     },
     "spell": ""
    }
   ],
   "spell_unlocks": [
    {
     "id": "blades",
     "branch": 0,
     "linked_index": 4,
     "max_rank": 1,
     "note": "Place spell before its specialization node; spell purchase needs only prior path, not the specialization node itself."
    },
    {
     "id": "lance",
     "branch": 0,
     "linked_index": 6,
     "max_rank": 1,
     "note": "Place spell before its specialization node; spell purchase needs only prior path, not the specialization node itself."
    },
    {
     "id": "frost",
     "branch": 1,
     "linked_index": 2,
     "max_rank": 1,
     "note": "Place spell before its specialization node; spell purchase needs only prior path, not the specialization node itself."
    },
    {
     "id": "gravity",
     "branch": 1,
     "linked_index": 8,
     "max_rank": 1,
     "note": "Place spell before its specialization node; spell purchase needs only prior path, not the specialization node itself."
    },
    {
     "id": "ground",
     "branch": 2,
     "linked_index": 4,
     "max_rank": 1,
     "note": "Place spell before its specialization node; spell purchase needs only prior path, not the specialization node itself."
    }
   ],
   "capacity": 140
  },
  "warden": {
   "branches": [
    {
     "id": "guard",
     "name": "Guard",
     "description": "Armor, Aegis and time to recover your footing"
    },
    {
     "id": "retribution",
     "name": "Retribution",
     "description": "Direct weapon pressure and disciplined spell strikes"
    },
    {
     "id": "sanctuary",
     "name": "Sanctuary",
     "description": "Ground control, recovery and protection for a held position"
    }
   ],
   "nodes": [
    {
     "id": "guard_iron_guard",
     "name": "Iron Guard",
     "branch": 0,
     "index": 0,
     "max_rank": 5,
     "effects": {
      "armor": 2
     },
     "spell": ""
    },
    {
     "id": "guard_stalwart",
     "name": "Stalwart",
     "branch": 0,
     "index": 1,
     "max_rank": 5,
     "effects": {
      "hp": 0.02
     },
     "spell": ""
    },
    {
     "id": "guard_deep_aegis",
     "name": "Deep Aegis",
     "branch": 0,
     "index": 2,
     "max_rank": 5,
     "effects": {
      "shield": 0.02
     },
     "spell": ""
    },
    {
     "id": "guard_aegis_vigil",
     "name": "Aegis Vigil",
     "branch": 0,
     "index": 3,
     "max_rank": 4,
     "effects": {
      "class_cooldown": 0.03
     },
     "spell": ""
    },
    {
     "id": "guard_defensive_works",
     "name": "Defensive Works",
     "branch": 0,
     "index": 4,
     "max_rank": 4,
     "effects": {
      "structure_hp": 0.05
     },
     "spell": ""
    },
    {
     "id": "guard_layered_aegis",
     "name": "Layered Aegis",
     "branch": 0,
     "index": 5,
     "max_rank": 4,
     "effects": {
      "shield": 0.02
     },
     "spell": ""
    },
    {
     "id": "guard_winter_wall",
     "name": "Winter Wall",
     "branch": 0,
     "index": 6,
     "max_rank": 4,
     "effects": {
      "spell_damage_by_id": {
       "frost": 0.04
      }
     },
     "spell": ""
    },
    {
     "id": "guard_tempered_guard",
     "name": "Tempered Guard",
     "branch": 0,
     "index": 7,
     "max_rank": 3,
     "effects": {
      "armor": 2
     },
     "spell": ""
    },
    {
     "id": "guard_winter_vigil",
     "name": "Winter Vigil",
     "branch": 0,
     "index": 8,
     "max_rank": 3,
     "effects": {
      "spell_cooldown_by_id": {
       "frost": 0.03
      }
     },
     "spell": ""
    },
    {
     "id": "guard_unbroken",
     "name": "Unbroken",
     "branch": 0,
     "index": 9,
     "max_rank": 3,
     "effects": {
      "hp": 0.02
     },
     "spell": ""
    },
    {
     "id": "guard_resolute_step",
     "name": "Resolute Step",
     "branch": 0,
     "index": 10,
     "max_rank": 3,
     "effects": {
      "dodge_cooldown": 0.04
     },
     "spell": ""
    },
    {
     "id": "guard_constant_vigil",
     "name": "Constant Vigil",
     "branch": 0,
     "index": 11,
     "max_rank": 2,
     "effects": {
      "class_cooldown": 0.03
     },
     "spell": ""
    },
    {
     "id": "retribution_firm_hand",
     "name": "Firm Hand",
     "branch": 1,
     "index": 0,
     "max_rank": 5,
     "effects": {
      "basic_damage": 0.02
     },
     "spell": ""
    },
    {
     "id": "retribution_judgment_lance",
     "name": "Judgment Lance",
     "branch": 1,
     "index": 1,
     "max_rank": 5,
     "effects": {
      "spell_damage_by_id": {
       "lance": 0.04
      }
     },
     "spell": ""
    },
    {
     "id": "retribution_avenging_blades",
     "name": "Avenging Blades",
     "branch": 1,
     "index": 2,
     "max_rank": 5,
     "effects": {
      "spell_damage_by_id": {
       "blades": 0.04
      }
     },
     "spell": ""
    },
    {
     "id": "retribution_lance_discipline",
     "name": "Lance Discipline",
     "branch": 1,
     "index": 3,
     "max_rank": 4,
     "effects": {
      "spell_cooldown_by_id": {
       "lance": 0.02
      }
     },
     "spell": ""
    },
    {
     "id": "retribution_blade_discipline",
     "name": "Blade Discipline",
     "branch": 1,
     "index": 4,
     "max_rank": 4,
     "effects": {
      "spell_cooldown_by_id": {
       "blades": 0.02
      }
     },
     "spell": ""
    },
    {
     "id": "retribution_steadfast_strikes",
     "name": "Steadfast Strikes",
     "branch": 1,
     "index": 5,
     "max_rank": 4,
     "effects": {
      "basic_damage": 0.015
     },
     "spell": ""
    },
    {
     "id": "retribution_storm_judgment",
     "name": "Storm Judgment",
     "branch": 1,
     "index": 6,
     "max_rank": 4,
     "effects": {
      "spell_damage_by_id": {
       "chain": 0.04
      }
     },
     "spell": ""
    },
    {
     "id": "retribution_consecrated_force",
     "name": "Consecrated Force",
     "branch": 1,
     "index": 7,
     "max_rank": 3,
     "effects": {
      "spell_damage": 0.02
     },
     "spell": ""
    },
    {
     "id": "retribution_storm_discipline",
     "name": "Storm Discipline",
     "branch": 1,
     "index": 8,
     "max_rank": 3,
     "effects": {
      "spell_cooldown_by_id": {
       "chain": 0.03
      }
     },
     "spell": ""
    },
    {
     "id": "retribution_vigilant_emplacements",
     "name": "Vigilant Emplacements",
     "branch": 1,
     "index": 9,
     "max_rank": 3,
     "effects": {
      "structure_damage": 0.05
     },
     "spell": ""
    },
    {
     "id": "retribution_weight_of_judgment",
     "name": "Weight of Judgment",
     "branch": 1,
     "index": 10,
     "max_rank": 3,
     "effects": {
      "spell_damage_by_id": {
       "gravity": 0.05
      }
     },
     "spell": ""
    },
    {
     "id": "retribution_oathbound_strikes",
     "name": "Oathbound Strikes",
     "branch": 1,
     "index": 11,
     "max_rank": 2,
     "effects": {
      "basic_damage": 0.02
     },
     "spell": ""
    },
    {
     "id": "sanctuary_hallowed_ground",
     "name": "Hallowed Ground",
     "branch": 2,
     "index": 0,
     "max_rank": 5,
     "effects": {
      "spell_damage_by_id": {
       "ground": 0.04
      }
     },
     "spell": ""
    },
    {
     "id": "sanctuary_sanctuary_rhythm",
     "name": "Sanctuary Rhythm",
     "branch": 2,
     "index": 1,
     "max_rank": 5,
     "effects": {
      "spell_cooldown_by_id": {
       "ground": 0.02
      }
     },
     "spell": ""
    },
    {
     "id": "sanctuary_healing_stores",
     "name": "Healing Stores",
     "branch": 2,
     "index": 2,
     "max_rank": 5,
     "effects": {
      "medkit": 0.01
     },
     "spell": ""
    },
    {
     "id": "sanctuary_pilgrim_s_reach",
     "name": "Pilgrim's Reach",
     "branch": 2,
     "index": 3,
     "max_rank": 4,
     "effects": {
      "pickup": 0.05
     },
     "spell": ""
    },
    {
     "id": "sanctuary_mending_works",
     "name": "Mending Works",
     "branch": 2,
     "index": 4,
     "max_rank": 4,
     "effects": {
      "repair": 0.05
     },
     "spell": ""
    },
    {
     "id": "sanctuary_guardian_wisp",
     "name": "Guardian Wisp",
     "branch": 2,
     "index": 5,
     "max_rank": 4,
     "effects": {
      "spell_damage_by_id": {
       "wisp": 0.05
      }
     },
     "spell": ""
    },
    {
     "id": "sanctuary_quiet_focus",
     "name": "Quiet Focus",
     "branch": 2,
     "index": 6,
     "max_rank": 4,
     "effects": {
      "cooldown": 0.01
     },
     "spell": ""
    },
    {
     "id": "sanctuary_sheltered_works",
     "name": "Sheltered Works",
     "branch": 2,
     "index": 7,
     "max_rank": 3,
     "effects": {
      "structure_hp": 0.03
     },
     "spell": ""
    },
    {
     "id": "sanctuary_vigil_flame",
     "name": "Vigil Flame",
     "branch": 2,
     "index": 8,
     "max_rank": 3,
     "effects": {
      "spell_damage_by_id": {
       "ember": 0.05
      }
     },
     "spell": ""
    },
    {
     "id": "sanctuary_vigil_rhythm",
     "name": "Vigil Rhythm",
     "branch": 2,
     "index": 9,
     "max_rank": 3,
     "effects": {
      "spell_cooldown_by_id": {
       "ember": 0.03
      }
     },
     "spell": ""
    },
    {
     "id": "sanctuary_sacred_routine",
     "name": "Sacred Routine",
     "branch": 2,
     "index": 10,
     "max_rank": 3,
     "effects": {
      "interact_speed": 0.05
     },
     "spell": ""
    },
    {
     "id": "sanctuary_pilgrim_s_pace",
     "name": "Pilgrim's Pace",
     "branch": 2,
     "index": 11,
     "max_rank": 2,
     "effects": {
      "speed": 0.02
     },
     "spell": ""
    }
   ],
   "spell_unlocks": [
    {
     "id": "blades",
     "branch": 1,
     "linked_index": 2,
     "max_rank": 1,
     "note": "Place spell before its specialization node; spell purchase needs only prior path, not the specialization node itself."
    },
    {
     "id": "chain",
     "branch": 1,
     "linked_index": 6,
     "max_rank": 1,
     "note": "Place spell before its specialization node; spell purchase needs only prior path, not the specialization node itself."
    },
    {
     "id": "gravity",
     "branch": 1,
     "linked_index": 10,
     "max_rank": 1,
     "note": "Place spell before its specialization node; spell purchase needs only prior path, not the specialization node itself."
    },
    {
     "id": "wisp",
     "branch": 2,
     "linked_index": 5,
     "max_rank": 1,
     "note": "Place spell before its specialization node; spell purchase needs only prior path, not the specialization node itself."
    },
    {
     "id": "ember",
     "branch": 2,
     "linked_index": 8,
     "max_rank": 1,
     "note": "Place spell before its specialization node; spell purchase needs only prior path, not the specialization node itself."
    }
   ],
   "capacity": 140
  },
  "arcanist": {
   "branches": [
    {
     "id": "fire",
     "name": "Fire",
     "description": "Ember pressure and electrical follow-through"
    },
    {
     "id": "frost",
     "name": "Frost",
     "description": "Winter protection and steady area control"
    },
    {
     "id": "arcane",
     "name": "Arcane",
     "description": "Efficient casting, spatial spells and expedition utility"
    }
   ],
   "nodes": [
    {
     "id": "fire_kindled_ember",
     "name": "Kindled Ember",
     "branch": 0,
     "index": 0,
     "max_rank": 5,
     "effects": {
      "spell_damage_by_id": {
       "ember": 0.04
      }
     },
     "spell": ""
    },
    {
     "id": "fire_ember_rhythm",
     "name": "Ember Rhythm",
     "branch": 0,
     "index": 1,
     "max_rank": 5,
     "effects": {
      "spell_cooldown_by_id": {
       "ember": 0.02
      }
     },
     "spell": ""
    },
    {
     "id": "fire_wand_practice",
     "name": "Wand Practice",
     "branch": 0,
     "index": 2,
     "max_rank": 5,
     "effects": {
      "basic_damage": 0.02
     },
     "spell": ""
    },
    {
     "id": "fire_heat_hardened",
     "name": "Heat-Hardened",
     "branch": 0,
     "index": 3,
     "max_rank": 4,
     "effects": {
      "hp": 0.02
     },
     "spell": ""
    },
    {
     "id": "fire_conductive_sparks",
     "name": "Conductive Sparks",
     "branch": 0,
     "index": 4,
     "max_rank": 4,
     "effects": {
      "spell_damage_by_id": {
       "chain": 0.04
      }
     },
     "spell": ""
    },
    {
     "id": "fire_focused_flame",
     "name": "Focused Flame",
     "branch": 0,
     "index": 5,
     "max_rank": 4,
     "effects": {
      "spell_damage": 0.02
     },
     "spell": ""
    },
    {
     "id": "fire_spark_rhythm",
     "name": "Spark Rhythm",
     "branch": 0,
     "index": 6,
     "max_rank": 4,
     "effects": {
      "spell_cooldown_by_id": {
       "chain": 0.02
      }
     },
     "spell": ""
    },
    {
     "id": "fire_ember_salves",
     "name": "Ember Salves",
     "branch": 0,
     "index": 7,
     "max_rank": 3,
     "effects": {
      "medkit": 0.01
     },
     "spell": ""
    },
    {
     "id": "fire_furnace_works",
     "name": "Furnace Works",
     "branch": 0,
     "index": 8,
     "max_rank": 3,
     "effects": {
      "structure_damage": 0.05
     },
     "spell": ""
    },
    {
     "id": "fire_deep_combustion",
     "name": "Deep Combustion",
     "branch": 0,
     "index": 9,
     "max_rank": 3,
     "effects": {
      "spell_damage_by_id": {
       "ember": 0.01
      }
     },
     "spell": ""
    },
    {
     "id": "fire_pulse_ignition",
     "name": "Pulse Ignition",
     "branch": 0,
     "index": 10,
     "max_rank": 3,
     "effects": {
      "class_cooldown": 0.02
     },
     "spell": ""
    },
    {
     "id": "fire_blazing_focus",
     "name": "Blazing Focus",
     "branch": 0,
     "index": 11,
     "max_rank": 2,
     "effects": {
      "spell_damage": 0.02
     },
     "spell": ""
    },
    {
     "id": "frost_deep_frost",
     "name": "Deep Frost",
     "branch": 1,
     "index": 0,
     "max_rank": 5,
     "effects": {
      "spell_damage_by_id": {
       "frost": 0.04
      }
     },
     "spell": ""
    },
    {
     "id": "frost_frost_rhythm",
     "name": "Frost Rhythm",
     "branch": 1,
     "index": 1,
     "max_rank": 5,
     "effects": {
      "spell_cooldown_by_id": {
       "frost": 0.02
      }
     },
     "spell": ""
    },
    {
     "id": "frost_crystalline_shield",
     "name": "Crystalline Shield",
     "branch": 1,
     "index": 2,
     "max_rank": 5,
     "effects": {
      "shield": 0.03
     },
     "spell": ""
    },
    {
     "id": "frost_glacial_lance",
     "name": "Glacial Lance",
     "branch": 1,
     "index": 3,
     "max_rank": 4,
     "effects": {
      "spell_damage_by_id": {
       "lance": 0.04
      }
     },
     "spell": ""
    },
    {
     "id": "frost_rime_armor",
     "name": "Rime Armor",
     "branch": 1,
     "index": 4,
     "max_rank": 4,
     "effects": {
      "armor": 2
     },
     "spell": ""
    },
    {
     "id": "frost_frozen_ground",
     "name": "Frozen Ground",
     "branch": 1,
     "index": 5,
     "max_rank": 4,
     "effects": {
      "spell_damage_by_id": {
       "ground": 0.04
      }
     },
     "spell": ""
    },
    {
     "id": "frost_lance_rhythm",
     "name": "Lance Rhythm",
     "branch": 1,
     "index": 6,
     "max_rank": 4,
     "effects": {
      "spell_cooldown_by_id": {
       "lance": 0.02
      }
     },
     "spell": ""
    },
    {
     "id": "frost_ground_rhythm",
     "name": "Ground Rhythm",
     "branch": 1,
     "index": 7,
     "max_rank": 3,
     "effects": {
      "spell_cooldown_by_id": {
       "ground": 0.03
      }
     },
     "spell": ""
    },
    {
     "id": "frost_winter_endurance",
     "name": "Winter Endurance",
     "branch": 1,
     "index": 8,
     "max_rank": 3,
     "effects": {
      "hp": 0.02
     },
     "spell": ""
    },
    {
     "id": "frost_gliding_escape",
     "name": "Gliding Escape",
     "branch": 1,
     "index": 9,
     "max_rank": 3,
     "effects": {
      "dodge_cooldown": 0.04
     },
     "spell": ""
    },
    {
     "id": "frost_cold_repairs",
     "name": "Cold Repairs",
     "branch": 1,
     "index": 10,
     "max_rank": 3,
     "effects": {
      "repair": 0.05
     },
     "spell": ""
    },
    {
     "id": "frost_perfected_crystal",
     "name": "Perfected Crystal",
     "branch": 1,
     "index": 11,
     "max_rank": 2,
     "effects": {
      "shield": 0.02
     },
     "spell": ""
    },
    {
     "id": "arcane_arcane_channels",
     "name": "Arcane Channels",
     "branch": 2,
     "index": 0,
     "max_rank": 5,
     "effects": {
      "cooldown": 0.01
     },
     "spell": ""
    },
    {
     "id": "arcane_empowered_wisp",
     "name": "Empowered Wisp",
     "branch": 2,
     "index": 1,
     "max_rank": 5,
     "effects": {
      "spell_damage_by_id": {
       "wisp": 0.04
      }
     },
     "spell": ""
    },
    {
     "id": "arcane_dense_singularity",
     "name": "Dense Singularity",
     "branch": 2,
     "index": 2,
     "max_rank": 5,
     "effects": {
      "spell_damage_by_id": {
       "gravity": 0.04
      }
     },
     "spell": ""
    },
    {
     "id": "arcane_singularity_rhythm",
     "name": "Singularity Rhythm",
     "branch": 2,
     "index": 3,
     "max_rank": 4,
     "effects": {
      "spell_cooldown_by_id": {
       "gravity": 0.02
      }
     },
     "spell": ""
    },
    {
     "id": "arcane_spectral_pattern",
     "name": "Spectral Pattern",
     "branch": 2,
     "index": 4,
     "max_rank": 4,
     "effects": {
      "spell_damage_by_id": {
       "blades": 0.04
      }
     },
     "spell": ""
    },
    {
     "id": "arcane_pulse_rhythm",
     "name": "Pulse Rhythm",
     "branch": 2,
     "index": 5,
     "max_rank": 4,
     "effects": {
      "class_cooldown": 0.02
     },
     "spell": ""
    },
    {
     "id": "arcane_pattern_rhythm",
     "name": "Pattern Rhythm",
     "branch": 2,
     "index": 6,
     "max_rank": 4,
     "effects": {
      "spell_cooldown_by_id": {
       "blades": 0.02
      }
     },
     "spell": ""
    },
    {
     "id": "arcane_distant_collection",
     "name": "Distant Collection",
     "branch": 2,
     "index": 7,
     "max_rank": 3,
     "effects": {
      "pickup": 0.05
     },
     "spell": ""
    },
    {
     "id": "arcane_light_step",
     "name": "Light Step",
     "branch": 2,
     "index": 8,
     "max_rank": 3,
     "effects": {
      "speed": 0.02
     },
     "spell": ""
    },
    {
     "id": "arcane_ritual_familiarity",
     "name": "Ritual Familiarity",
     "branch": 2,
     "index": 9,
     "max_rank": 3,
     "effects": {
      "interact_speed": 0.05
     },
     "spell": ""
    },
    {
     "id": "arcane_arcane_bracing",
     "name": "Arcane Bracing",
     "branch": 2,
     "index": 10,
     "max_rank": 3,
     "effects": {
      "structure_hp": 0.05
     },
     "spell": ""
    },
    {
     "id": "arcane_wand_mastery",
     "name": "Wand Mastery",
     "branch": 2,
     "index": 11,
     "max_rank": 2,
     "effects": {
      "basic_damage": 0.03
     },
     "spell": ""
    }
   ],
   "spell_unlocks": [
    {
     "id": "chain",
     "branch": 0,
     "linked_index": 4,
     "max_rank": 1,
     "note": "Place spell before its specialization node; spell purchase needs only prior path, not the specialization node itself."
    },
    {
     "id": "lance",
     "branch": 1,
     "linked_index": 3,
     "max_rank": 1,
     "note": "Place spell before its specialization node; spell purchase needs only prior path, not the specialization node itself."
    },
    {
     "id": "ground",
     "branch": 1,
     "linked_index": 5,
     "max_rank": 1,
     "note": "Place spell before its specialization node; spell purchase needs only prior path, not the specialization node itself."
    },
    {
     "id": "gravity",
     "branch": 2,
     "linked_index": 2,
     "max_rank": 1,
     "note": "Place spell before its specialization node; spell purchase needs only prior path, not the specialization node itself."
    },
    {
     "id": "blades",
     "branch": 2,
     "linked_index": 4,
     "max_rank": 1,
     "note": "Place spell before its specialization node; spell purchase needs only prior path, not the specialization node itself."
    }
   ],
   "capacity": 140
  }
 }
}
const CAPS := {"hp":0.20,"power":0.0,"armor":18.0,"speed":0.10,"pickup":0.30,"cooldown":0.08,"medkit":0.05,"capacity":1.0,"secure":1.0}
const EFFECT_CAPS := {"basic_damage":0.20,"spell_damage":0.15,"structure_damage":0.25,"structure_hp":0.30,"repair":0.30,"dodge_cooldown":0.20,"class_cooldown":0.20,"shield":0.20,"interact_speed":0.25,"spell_damage_by_id":0.25,"spell_cooldown_by_id":0.15}
static var catalog: Dictionary = {}

static func branches(class_id: String) -> Array:
 return DESIGN.classes[class_id].branches

static func nodes(class_id: String) -> Array:
 if not catalog.has(class_id):
  var result: Array=DESIGN.classes[class_id].nodes.duplicate(true)
  var grouped: Dictionary={}
  for entry: Dictionary in result:
   grouped[str(entry.branch)+":"+str(entry.index)]=entry
   entry.row=ROWS[entry.index]
   entry.column=entry.branch
   entry.position=Vector2(POSITIONS[entry.index].x,80+(POSITIONS[entry.index].y-80)*1.25)
   entry.gate=DESIGN.class_spend_gates_by_index[entry.index]
   entry.parents=[]
   entry.stat=""
   var key: String=entry.effects.keys()[0]
   entry.icon=entry.effects[key].keys()[0] if entry.effects[key] is Dictionary else key
   if key in CAPS:entry.stat=key
  for entry: Dictionary in result:
   for index in DESIGN.links[entry.index]:
    entry.parents.append(grouped[str(entry.branch)+":"+str(index)].id)
  var unlocks: Array=[]
  for unlock: Dictionary in DESIGN.classes[class_id].spell_unlocks:
   var specialization: Dictionary=grouped[str(unlock.branch)+":"+str(unlock.linked_index)]
   var parent_position:=Vector2.ZERO
   for parent: String in specialization.parents:
    for other: Dictionary in result:
     if other.id==parent:parent_position+=other.position
   parent_position/=maxi(1,specialization.parents.size())
   var spell: Dictionary={"id":unlock.id,"name":Combat.SPELLS[unlock.id].name,"branch":unlock.branch,"index":12+unlocks.size(),"row":specialization.row-0.25,"column":unlock.branch,"max_rank":1,"spell":unlock.id,"stat":"","icon":unlock.id,"effects":{},"gate":specialization.gate,"parents":specialization.parents.duplicate(),"position":parent_position.lerp(specialization.position,0.50)}
   specialization.parents=[unlock.id]
   unlocks.append(spell)
  result.append_array(unlocks)
  catalog[class_id]=result
 return catalog[class_id]

static func branch_nodes(class_id: String, branch: int) -> Array:
 return nodes(class_id).filter(func(entry: Dictionary):return entry.branch==branch)

static func node(class_id: String, id: String) -> Dictionary:
 if class_id not in STARTERS:return {}
 for entry: Dictionary in nodes(class_id):
  if entry.id==id:return entry
 return {}

static func cost(class_id: String, id: String) -> int:
 return 0 if node(class_id,id).is_empty() else 1

static func legacy_cost(class_id: String, id: String) -> int:
 var index: int=BRANCHES.get(class_id,[]).find(id)
 return COSTS[index] if index>=0 else 0

static func parents(class_id: String, id: String) -> Array:
 return node(class_id,id).get("parents",[])

static func required_rank(class_id: String, id: String) -> int:
 var incoming:=parents(class_id,id)
 return node(class_id,incoming[0]).max_rank if not incoming.is_empty() else 0

static func pool(class_id: String, unlocks: Array) -> Array:
 var result: Array=STARTERS[class_id].duplicate()
 for id in BRANCHES[class_id]:
  if id in unlocks:result.append(id)
 return result

static func spent(_class_id: String, ranks: Variant) -> int:
 if ranks is Array:return ranks.size()
 var total:=0
 for rank in ranks.values():total+=int(rank)
 return total

static func prior_spent(class_id: String, row: float, ranks: Dictionary) -> int:
 var total:=0
 for entry: Dictionary in nodes(class_id):
  if entry.row<row:total+=int(ranks.get(entry.id,0))
 return total

static func requirement(class_id: String, id: String, ranks: Dictionary) -> String:
 var definition:=node(class_id,id)
 if definition.is_empty():return "Unknown talent"
 if prior_spent(class_id,definition.row,ranks)<definition.gate:
  return "Spend %d points in earlier tiers" % definition.gate
 var incoming:=parents(class_id,id)
 if incoming.is_empty():return ""
 var names:=PackedStringArray()
 for parent: String in incoming:
  var source:=node(class_id,parent)
  if int(ranks.get(parent,0))>=source.max_rank:return ""
  names.append(source.name)
 return "Finish "+" or ".join(names)

static func prerequisites_met(class_id: String, id: String, unlocks: Array) -> bool:
 for parent in parents(class_id,id):
  if parent in unlocks:return true
 return parents(class_id,id).is_empty()

static func valid(class_id: String, ranks: Variant, inherited: Array=[]) -> bool:
 if not ranks is Dictionary:return false
 for id in ranks:
  var definition:=node(class_id,id)
  if definition.is_empty() or not ranks[id] is int or ranks[id]<1 or ranks[id]>definition.max_rank:return false
 for id in ranks:
  if id not in inherited and not requirement(class_id,id,ranks).is_empty():return false
 return spent(class_id,ranks)<=POINT_CAP

static func bonuses(class_id: String, ranks: Dictionary) -> Dictionary:
 var result: Dictionary={}
 for key in CAPS:result[key]=0.0
 for definition in nodes(class_id):
  for key in definition.effects:
   if key in CAPS:result[key]+=float(definition.effects[key])*int(ranks.get(definition.id,0))
 for key in CAPS:result[key]=minf(result[key],CAPS[key])
 return result

static func effect_bonuses(class_id: String, ranks: Dictionary) -> Dictionary:
 var result: Dictionary={}
 for key in EFFECT_CAPS:result[key]={} if key.ends_with("_by_id") else 0.0
 for definition in nodes(class_id):
  var rank: int=ranks.get(definition.id,0)
  for key in definition.effects:
   if key not in EFFECT_CAPS:continue
   if definition.effects[key] is Dictionary:
    for spell in definition.effects[key]:result[key][spell]=result[key].get(spell,0.0)+float(definition.effects[key][spell])*rank
   else:result[key]+=float(definition.effects[key])*rank
 for key in EFFECT_CAPS:
  if result[key] is Dictionary:
   for spell in result[key]:result[key][spell]=minf(result[key][spell],EFFECT_CAPS[key])
  else:result[key]=minf(result[key],EFFECT_CAPS[key])
 return result

static func description(class_id: String, id: String) -> String:
 var definition:=node(class_id,id)
 if definition.is_empty():return ""
 if not definition.spell.is_empty():return "Unlock %s in this class's mission level-up choices." % definition.name
 var names: Dictionary={"basic_damage":"basic attack damage","spell_damage":"all spell damage","structure_damage":"structure damage","structure_hp":"structure HP","repair":"repair strength","dodge_cooldown":"dodge cooldown reduction","class_cooldown":"class skill cooldown reduction","shield":"shield strength","interact_speed":"interaction speed","hp":"starting HP","armor":"armor","speed":"movement speed","pickup":"pickup radius","cooldown":"all cooldown reduction","medkit":"medkit healing","capacity":"pack slot","secure":"secure slot"}
 var effects:=PackedStringArray()
 for key in definition.effects:
  var value: Variant=definition.effects[key]
  if value is Dictionary:
   for spell in value:
    effects.append("+%.0f%% %s %s per rank" % [float(value[spell])*100.0,Combat.SPELLS[spell].name,"damage" if key=="spell_damage_by_id" else "cooldown reduction"])
  elif key in ["armor","capacity","secure"]:effects.append("+%s %s per rank" % [str(value),names[key]])
  else:effects.append("+%.1f%% %s per rank" % [float(value)*100.0,names.get(key,key)])
 return ". ".join(effects)+"."
