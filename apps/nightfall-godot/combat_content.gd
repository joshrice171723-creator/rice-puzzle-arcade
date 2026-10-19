extends RefCounted
## Starting values for the first playable combat slice, not campaign balance.

const POWER := 40.0
const ENEMIES := {
	"drifter": {"name": "Drifter", "hp": 48.0, "speed": 32.0, "contact": 10.0},
	"runner": {"name": "Rift Runner", "hp": 32.0, "speed": 56.0, "contact": 8.0},
	"spitter": {"name": "Ash Spitter", "hp": 40.0, "speed": 24.0, "contact": 8.0},
	"breaker": {"name": "The Breaker", "hp": 1000.0, "speed": 35.0, "contact": 18.0},
}
const SPELLS := {
	"ember": {"name": "Ember Bolt", "cooldown": 5.0, "description": "36 impact + 12 burn over 2s. One target."},
	"frost": {"name": "Frost Ring", "cooldown": 8.0, "description": "26 nearby damage. Chill foes for 3s."},
	"chain": {"name": "Chain Spark", "cooldown": 7.0, "description": "28 / 18 / 12 damage across 3 nearby foes."},
}
const WAVES := [
	{"at": 0.0, "name": "Dusk patrol", "interval": 1.4, "runner": 0.0, "spitter": 0.0},
	{"at": 45.0, "name": "Runners arrive", "interval": 1.05, "runner": 0.25, "spitter": 0.0},
	{"at": 100.0, "name": "Crossfire", "interval": 0.80, "runner": 0.25, "spitter": 0.25},
	{"at": 165.0, "name": "Last stand", "interval": 0.60, "runner": 0.35, "spitter": 0.25},
]

static func wave_at(seconds: float) -> Dictionary:
	var wave: Dictionary = WAVES[0]
	for candidate in WAVES:
		if seconds >= candidate.at:
			wave = candidate
	return wave
