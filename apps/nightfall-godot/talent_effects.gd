extends RefCounted
## Validated attempt-local effects of permanent class talent allocations.
const CAPS := {"basic_damage":0.20,"spell_damage":0.15,"structure_damage":0.25,"structure_hp":0.30,"repair":0.30,"dodge_cooldown":0.20,"class_cooldown":0.20,"shield":0.20,"interact_speed":0.25}
const SPELLS = preload("res://combat_content.gd").SPELLS
static func normalized(value: Variant) -> Dictionary:
 var result := {}
 for key in CAPS:
  var amount: Variant=value.get(key,0.0) if value is Dictionary else 0.0
  result[key]=clampf(float(amount),0,CAPS[key]) if (amount is int or amount is float) and is_finite(float(amount)) else 0.0
 for key in ["spell_damage_by_id","spell_cooldown_by_id"]:
  result[key]={}
  var values: Variant=value.get(key,{}) if value is Dictionary else {}
  if values is Dictionary:
   for id in SPELLS:
    var amount: Variant=values.get(id,0.0)
    result[key][id]=clampf(float(amount),0,0.25 if key=="spell_damage_by_id" else 0.15) if (amount is int or amount is float) and is_finite(float(amount)) else 0.0
 return result
