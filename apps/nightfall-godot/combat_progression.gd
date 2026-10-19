extends RefCounted
## Permanent training. Mission XP, gear rarity and class mastery remain separate.
const STATS := ["attack", "strength", "defence", "ranged", "magic", "vitality"]
const STYLES := {
	"accurate": {"name": "Accurate", "skills": ["attack"]},
	"powerful": {"name": "Powerful", "skills": ["strength"]},
	"guarded": {"name": "Guarded", "skills": ["defence"]},
	"ranged": {"name": "Ranged", "skills": ["ranged"]},
	"arcane": {"name": "Arcane", "skills": ["magic"]},
	"balanced": {"name": "Balanced", "skills": ["attack", "strength", "defence"]}}
const MAX_XP := 2172405.0
static var thresholds: Array[int] = []

static func fresh() -> Dictionary:
	return {"attack": 0.0, "strength": 0.0, "defence": 0.0, "ranged": 0.0, "magic": 0.0, "vitality": 0.0}

static func threshold(stat_level: int) -> int:
	if thresholds.is_empty():
		thresholds.append(0)
		var total := 0
		for n in range(1, 99):
			total += int(floor(n + 300.0 * pow(2.0, n / 7.0)))
			thresholds.append(int(floor(floor(total / 4.0) / 6.0)))
	return thresholds[clampi(stat_level, 1, 99) - 1]

static func level(xp: float) -> int:
	var result := 1
	while result < 99 and xp >= threshold(result + 1):
		result += 1
	return result

static func valid(xp: Variant) -> bool:
	if not xp is Dictionary or xp.size() != STATS.size():
		return false
	for id in STATS:
		var value: Variant = xp.get(id)
		if not (value is int or value is float) or not is_finite(float(value)) or value < 0 or value > MAX_XP:
			return false
	return true

static func combat_level(xp: Dictionary) -> int:
	var total := 0
	for id in STATS:
		total += level(xp.get(id, 0.0))
	return clampi(int(floor(total / 6.0)), 1, 99)

static func award(xp: Dictionary, style: String, effective_hp: float, spawn_hp: float, boss: bool) -> void:
	if style not in STYLES or spawn_hp <= 0 or effective_hp <= 0:
		return
	var amount := effective_hp / spawn_hp * (240.0 if boss else 24.0)
	var skills: Array = STYLES[style].skills
	for id in skills:
		xp[id] = minf(MAX_XP, xp[id] + amount / skills.size())
	xp.vitality = minf(MAX_XP, xp.vitality + amount / 3.0)

static func bonuses(xp: Dictionary) -> Dictionary:
	return {"crit": (level(xp.attack) - 1) / 98.0 * 0.10,
		"physical": (level(xp.strength) + level(xp.ranged) - 2) / 98.0 * 0.20,
		"magic": (level(xp.magic) - 1) / 98.0 * 0.30,
		"reduction": (level(xp.defence) - 1) / 98.0 * 0.15,
		"hp": (level(xp.vitality) - 1) / 98.0 * 0.30}

static func valid_bonuses(value: Variant) -> bool:
	var caps := {"crit": 0.10, "physical": 0.40, "magic": 0.30, "reduction": 0.15, "hp": 0.30}
	if not value is Dictionary or value.size() != caps.size():
		return false
	for key in caps:
		var amount: Variant = value.get(key)
		if not (amount is int or amount is float) or not is_finite(float(amount)) or amount < 0 or amount > caps[key] + 0.000001:
			return false
	return true
