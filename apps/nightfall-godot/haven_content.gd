extends RefCounted

const SLOTS := ["weapon", "helmet", "body", "boots", "charm", "gadget"]
const RARITIES := ["common", "uncommon", "rare", "epic", "legendary", "mythic"]
const RARITY_SCALE := [1.0, 1.04, 1.08, 1.12, 1.16, 1.20]
const RARITY_COLORS := ["a4aaba", "92afc4", "78adff", "ba92ff", "ffd27c", "ed7997"]
const STARTER_NAMES := ["Service Pistol", "Outrider Hood", "Outrider Vest", "Outrider Boots", "Beacon Pendant", "Field Medkit"]
const BASE_STATS := {
	"weapon": {"power": 40.0, "hp": 0.0, "armor": 0.0},
	"helmet": {"power": 0.0, "hp": 20.0, "armor": 10.0},
	"body": {"power": 0.0, "hp": 50.0, "armor": 20.0},
	"boots": {"power": 0.0, "hp": 10.0, "armor": 5.0},
	"charm": {"power": 0.0, "hp": 10.0, "armor": 0.0},
	"gadget": {"power": 0.0, "hp": 0.0, "armor": 0.0}}
const CLASSES := {
	"scavenger": {"name": "Scavenger", "description": "+5% movement speed, +15% XP pickup reach.", "unlock": "Available", "ability": "Phase Step", "cooldown": 12.0},
	"engineer": {"name": "Engineer", "description": "Structures gain +10% health. Repair Swarm restores a structure.", "unlock": "Clear Outskirts mission 4", "ability": "Repair Swarm", "cooldown": 24.0},
	"warden": {"name": "Warden", "description": "+10% maximum health and +18 armor. Aegis absorbs damage.", "unlock": "Clear Zone 2 (future content)", "ability": "Aegis", "cooldown": 22.0},
	"arcanist": {"name": "Arcanist", "description": "+8% elemental damage. Rift Pulse strikes nearby enemies.", "unlock": "Zone 3 mission 3 (future content)", "ability": "Rift Pulse", "cooldown": 16.0}}
const MISSIONS := [
	{"name": "Garage Lights", "boss": "Garage Mauler", "duration": 240.0, "health": 700.0, "pressure": 0.85, "attacks": ["slam", "rush"], "intro": "Scavenge the garages before the Mauler arrives."},
	{"name": "Beyond the Fence", "boss": "Fence Runner", "duration": 240.0, "health": 820.0, "pressure": 0.95, "attacks": ["rush", "rush", "toss"], "intro": "Keep a path open through the yard."},
	{"name": "Hollow Porches", "boss": "Porchcaller", "duration": 240.0, "health": 900.0, "pressure": 1.05, "attacks": ["summon", "toss", "slam"], "intro": "The Porchcaller's cries draw more undead."},
	{"name": "Scrapwall", "boss": "Scrapback", "duration": 240.0, "health": 1000.0, "pressure": 1.15, "attacks": ["slam", "toss", "rush"], "intro": "Circle Scrapback to strike its exposed rear."},
	{"name": "The Last Street", "boss": "The Breaker", "duration": 240.0, "health": 1200.0, "pressure": 1.25, "attacks": ["rush", "slam", "toss"], "intro": "Break the siege of the Outskirts beacon."}]
const FACILITIES := {
	"workshop": {"name": "Workshop", "description": "Upgrade and promote equipment. Rank 2 reduces upgrade credit costs by 10%.", "credits": 400, "parts": 12},
	"quartermaster": {"name": "Quartermaster", "description": "Adds one backpack slot per rank. Protected slots stay at two.", "credits": 300, "parts": 10},
	"infirmary": {"name": "Infirmary", "description": "Improves your once-per-run Field Medkit from 20% to 25% maximum HP.", "credits": 350, "parts": 12}}

static func item_stats(item: Dictionary) -> Dictionary:
	var stats: Dictionary = BASE_STATS[item.slot].duplicate()
	var rank := RARITIES.find(item.rarity)
	var multiplier: float = (1.0 + 0.05 * (item.level - 1)) * RARITY_SCALE[maxi(0, rank)]
	for stat: String in stats:
		stats[stat] *= multiplier
	return stats

static func survivor_level(xp: int) -> int:
	var level := 1
	var remaining := xp
	while level < 40 and remaining >= level * 120:
		remaining -= level * 120
		level += 1
	return level

static func mastery_level(xp: int) -> int:
	var level := 0
	var remaining := xp
	while level < 20 and remaining >= (level + 1) * 100:
		remaining -= (level + 1) * 100
		level += 1
	return level
