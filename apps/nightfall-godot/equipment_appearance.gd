extends RefCounted
## Eligibility-filtered visual loadout. No stats or progression are changed here.
const Content = preload("res://haven_content.gd")
const Weapons = preload("res://weapons.gd")
const ARMOR := ["helmet", "body", "pants", "boots"]
const ACCESSORIES := ["ring", "charm", "gadget"]
const FAMILIES := ["none", "outrider", "ironwatch", "riftweaver"]
const VERSION := 1
static var previews: Dictionary = {}

static func fresh(class_id: String = "scavenger", weapon: String = "pistol") -> Dictionary:
	return {"version":VERSION,"class":class_id,"slots":{"helmet":"none","body":"none","pants":"none","boots":"none"},
		"weapon":weapon,"accessories":{"ring":false,"charm":false,"gadget":false},"items":{}}

static func from_profile(profile: RefCounted, class_id: String = "", eligible_only: bool = true) -> Dictionary:
	var hero: String = profile.data["class"] if class_id.is_empty() else class_id
	var result := fresh(hero)
	for slot: String in Content.SLOTS:
		var item: Dictionary = profile.item_by_id(int(profile.data.equipment.get(slot,-1)))
		if item.is_empty() or (eligible_only and not profile.equipment_eligible(item,hero)):
			continue
		result.items[slot] = {"id":int(item.id),"name":String(item.name),"rarity":String(item.rarity)}
		if slot in ARMOR:
			var family := Content.set_id(item)
			result.slots[slot] = family if family in FAMILIES else "none"
		elif slot == "weapon":
			result.weapon = Weapons.family(item)
		elif slot in ACCESSORIES:
			result.accessories[slot] = true
	return result

static func valid(value: Variant) -> bool:
	if not value is Dictionary or value.get("version") != VERSION or value.get("class") not in Content.CLASSES or value.get("weapon") not in Weapons.TYPES:
		return false
	if not value.get("slots") is Dictionary or value.slots.size()!=ARMOR.size() or not value.get("accessories") is Dictionary or value.accessories.size()!=ACCESSORIES.size() or not value.get("items") is Dictionary:
		return false
	for slot in ARMOR:
		if value.slots.get(slot) not in FAMILIES:
			return false
	for slot in ACCESSORIES:
		if not value.accessories.get(slot) is bool:
			return false
	for slot in value.items:
		var item: Variant = value.items[slot]
		if slot not in Content.SLOTS or not item is Dictionary or not item.get("id") is int or item.id<0 or not item.get("name") is String or item.get("rarity") not in Content.RARITIES:
			return false
	return true

static func signature(value: Dictionary) -> String:
	var result: String = value.get("class","scavenger")
	for slot in ARMOR:
		result += ":"+String(value.get("slots",{}).get(slot,"none"))
	result += ":"+String(value.get("weapon","pistol"))
	for slot in ACCESSORIES:
		result += ":1" if value.get("accessories",{}).get(slot,false) else ":0"
	return result

static func item_preview(item: Dictionary) -> Texture2D:
	# Inventory and worn armor sample the same authored material/silhouette.
	# Read original manifests: the renderer may repack its in-memory regions.
	if item.get("slot") not in ARMOR:return null
	var family := Content.set_id(item)
	if family.is_empty():return null
	var key: String=family+":"+String(item.slot)
	if previews.has(key):return previews[key]
	var path: String="res://assets/actor-rigs/gear_"+family+".json"
	if not FileAccess.file_exists(path):return null
	var definition: Variant=JSON.parse_string(FileAccess.get_file_as_string(path))
	var part_name: String={"helmet":"helmet","body":"torso","pants":"thigh","boots":"foot"}[item.slot]
	if not definition is Dictionary or not definition.get("parts") is Dictionary or not definition.parts.has(part_name) or not ResourceLoader.exists(definition.get("texture","")):
		return null
	var source: Variant=load(definition.texture)
	var region: Variant=definition.parts[part_name].get("region")
	if not source is Texture2D or not region is Array or region.size()!=4:return null
	var texture:=AtlasTexture.new()
	texture.atlas=source
	texture.region=Rect2(region[0],region[1],region[2],region[3])
	texture.filter_clip=true
	previews[key]=texture
	return texture
