extends RefCounted

const SLOTS := ["weapon", "helmet", "body", "boots", "charm", "gadget", "ring", "pants"]
const SLOT_LABELS := {"weapon": "Weapon", "helmet": "Head", "body": "Chest", "boots": "Boots", "charm": "Pendant", "gadget": "Gadget", "ring": "Ring", "pants": "Pants"}
const RARITIES := ["common", "uncommon", "rare", "epic", "legendary", "mythic"]
const RARITY_SCALE := [1.0, 1.04, 1.08, 1.12, 1.16, 1.20]
const MERGE_MAX_RARITY := "epic"
const RARITY_COLORS := ["a4aaba", "92afc4", "78adff", "ba92ff", "ffd27c", "ed7997"]
const STARTER_NAMES := ["Service Pistol", "Outrider Hood", "Outrider Vest", "Outrider Boots", "Beacon Pendant", "Field Medkit", "Beacon Ring", "Outrider Trousers"]
const ARMOR_SLOTS := ["helmet", "body", "boots", "pants"]
const SETS := {
	"outrider": {"name": "Outrider", "pieces": ["Outrider Hood", "Outrider Vest", "Outrider Boots", "Outrider Trousers"], "two": "+15% XP pickup reach", "three": "+1 protected loot slot"},
	"ironwatch": {"name": "Ironwatch", "pieces": ["Ironwatch Helm", "Ironwatch Cuirass", "Ironwatch Boots", "Ironwatch Greaves"], "two": "+12 armor", "three": "+6% maximum HP"},
	"riftweaver": {"name": "Riftweaver", "pieces": ["Riftweaver Cowl", "Riftweaver Robe", "Riftweaver Boots", "Riftweaver Leggings"], "two": "+3% spell damage", "three": "+4% spell cooldown reduction"}}
const AFFIXES := {
	"tempered": {"name": "Tempered", "description": "+3% this item's Power", "stat": "power", "value": 0.03, "slots": ["weapon"]},
	"reinforced": {"name": "Reinforced", "description": "+4% this item's HP", "stat": "hp", "value": 0.04, "slots": ["helmet", "body", "boots", "charm", "ring", "pants"]},
	"plated": {"name": "Plated", "description": "+4% this item's armor", "stat": "armor", "value": 0.04, "slots": ["helmet", "body", "boots", "pants"]},
	"attuned": {"name": "Attuned", "description": "+2% spell cooldown reduction", "stat": "cooldown", "value": 0.02, "slots": SLOTS},
	"seeking": {"name": "Seeking", "description": "+5% XP pickup reach", "stat": "pickup", "value": 0.05, "slots": SLOTS},
	"lightweight": {"name": "Lightweight", "description": "+1% movement speed", "stat": "speed", "value": 0.01, "slots": SLOTS}}
const BASE_STATS := {
	"weapon": {"power": 40.0, "hp": 0.0, "armor": 0.0},
	"helmet": {"power": 0.0, "hp": 20.0, "armor": 10.0},
	"body": {"power": 0.0, "hp": 40.0, "armor": 15.0},
	"boots": {"power": 0.0, "hp": 10.0, "armor": 5.0},
	"charm": {"power": 0.0, "hp": 5.0, "armor": 0.0},
	"ring": {"power": 0.0, "hp": 5.0, "armor": 0.0},
	"pants": {"power": 0.0, "hp": 10.0, "armor": 5.0},
	"gadget": {"power": 0.0, "hp": 0.0, "armor": 0.0}}
const CLASSES := {
	"scavenger": {"name": "Scavenger", "description": "+5% speed, +15% XP reach. Every 12s, your next Dodge becomes a longer Phase Step.", "unlock": "Available", "ability": "Phase Step", "cooldown": 12.0},
	"engineer": {"name": "Engineer", "description": "Structures gain +10% HP. Repair Swarm automatically repairs a nearby damaged structure.", "unlock": "Clear Outskirts mission 4", "ability": "Repair Swarm", "cooldown": 24.0},
	"warden": {"name": "Warden", "description": "+10% HP, +18 armor. Aegis automatically shields you when threats approach.", "unlock": "Clear Zone 2 (future content)", "ability": "Aegis", "cooldown": 22.0},
	"arcanist": {"name": "Arcanist", "description": "+8% elemental damage. Rift Pulse automatically strikes nearby enemies.", "unlock": "Zone 3 mission 3 (future content)", "ability": "Rift Pulse", "cooldown": 16.0}}
const MISSIONS := [
	{"name": "Garage Lights", "boss": "Garage Mauler", "duration": 240.0, "health": 700.0, "pressure": 0.85, "attacks": ["slam", "rush"], "intro": "Scavenge the garages before the Mauler arrives."},
	{"name": "Beyond the Fence", "boss": "Fence Runner", "duration": 240.0, "health": 820.0, "pressure": 0.95, "attacks": ["rush", "rush", "toss"], "intro": "Keep a path open through the yard."},
	{"name": "Hollow Porches", "boss": "Porchcaller", "duration": 240.0, "health": 900.0, "pressure": 1.05, "attacks": ["summon", "toss", "slam"], "intro": "The Porchcaller's cries draw more undead."},
	{"name": "Scrapwall", "boss": "Scrapback", "duration": 240.0, "health": 1000.0, "pressure": 1.15, "attacks": ["slam", "toss", "rush"], "intro": "Circle Scrapback to strike its exposed rear."},
	{"name": "The Last Street", "boss": "The Breaker", "duration": 240.0, "health": 1200.0, "pressure": 1.25, "attacks": ["rush", "slam", "toss"], "intro": "Break the siege of the Outskirts beacon."}]
const FACILITIES := {
	"workshop": {"name": "Workshop", "description": "Upgrade, merge and tune equipment. Rank 2 reduces item-level upgrade credit costs by 10%.", "credits": 400, "parts": 12},
	"quartermaster": {"name": "Storehouse", "description": "Rank 2 increases backpack capacity from 8 to 9. Protected slots stay at two.", "credits": 300, "parts": 10},
	"infirmary": {"name": "Infirmary", "description": "Improves your once-per-run Field Medkit from 20% to 25% maximum HP.", "credits": 350, "parts": 12}}

static func item_stats(item: Dictionary) -> Dictionary:
	if item.is_empty():
		return {"power":0.0,"hp":0.0,"armor":0.0}
	var stats: Dictionary = BASE_STATS[item.slot].duplicate()
	var rank := RARITIES.find(item.rarity)
	var multiplier: float = (1.0 + 0.05 * (item.level - 1)) * RARITY_SCALE[maxi(0, rank)]
	for stat: String in stats:
		stats[stat] *= multiplier
		for affix: String in item.get("affixes", []):
			if AFFIXES.has(affix) and AFFIXES[affix].stat == stat:
				stats[stat] *= 1.0 + affix_value(item, affix)
	return stats

static func set_id(item: Dictionary) -> String:
	for id: String in SETS:
		if item.get("name", "") in SETS[id].pieces:
			return id
	return ""

static func affix_rank(item: Dictionary, affix: String) -> int:
	return int(item.get("affix_levels", {}).get(affix, 1))

static func affix_value(item: Dictionary, affix: String) -> float:
	return AFFIXES[affix].value * (1.0 + 0.5 * (affix_rank(item, affix) - 1))

static func affix_text(item: Dictionary, affix: String) -> String:
	var targets := {"power": "item Power", "hp": "item HP", "armor": "item armor", "cooldown": "spell cooldown reduction", "pickup": "XP pickup reach", "speed": "movement speed"}
	return "%s %d/3 · +%.1f%% %s" % [AFFIXES[affix].name, affix_rank(item, affix), affix_value(item, affix) * 100, targets[AFFIXES[affix].stat]]

static func survivor_level(xp: int) -> int:
	var level := 1
	var remaining := xp
	while level < 40 and remaining >= level * 120:
		remaining -= level * 120
		level += 1
	return level

static func clear_rewards(mission: int) -> Dictionary:
	var scale := 1.5 if mission == 5 else 1.0
	return {"credits": roundi(165 * scale), "parts": roundi(3 * scale),
		"survivor_xp": roundi(85 * scale), "mastery_xp": roundi(45 * scale)}

static func mastery_level(xp: int) -> int:
	var level := 0
	var remaining := xp
	while level < 20 and remaining >= (level + 1) * 100:
		remaining -= (level + 1) * 100
		level += 1
	return level
