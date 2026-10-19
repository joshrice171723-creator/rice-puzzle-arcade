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
	"wisp": {"name": "Orbiting Wisp", "cooldown": 0.0, "description": "A circling wisp deals 25% Power on contact, at most once per enemy every 1.1s."},
	"lance": {"name": "Stone Lance", "cooldown": 9.0, "description": "140% Power through up to three enemies in a narrow line."},
	"ground": {"name": "Consecrated Ground", "cooldown": 12.0, "description": "A fixed circle deals 20% Power per second for four seconds."},
	"blades": {"name": "Spectral Blades", "cooldown": 6.0, "description": "Two blades each deal 55% Power to a nearby target."},
	"gravity": {"name": "Gravity Knot", "cooldown": 12.0, "description": "40% Power in an area. Pull ordinary enemies together; bosses resist."},
}
const PASSIVES := {
	"rounds": {"name": "Heavy Rounds", "description": "+4 pistol damage per rank, maximum 48.", "max_rank": 3},
	"quick": {"name": "Quick Hands", "description": "Fire 0.025s faster per rank, minimum 0.18s.", "max_rank": 3},
	"focus": {"name": "Arcane Focus", "description": "+6% spell damage per rank. Pairs with Ember Bolt.", "max_rank": 3},
	"vital": {"name": "Vital Reserve", "description": "+8% base maximum health per rank. Pairs with Frost Ring.", "max_rank": 3},
	"fleet": {"name": "Fleet Foot", "description": "+5% movement speed per rank. Total movement bonus capped at 30%.", "max_rank": 3},
	"mechanic": {"name": "Field Mechanic", "description": "+6% structure damage and +10% repair strength per rank. Pairs with Chain Spark.", "max_rank": 3},
	"magnet": {"name": "Magnetic Harness", "description": "+20% XP pickup radius per rank. Pairs with Orbiting Wisp.", "max_rank": 3},
	"pierce": {"name": "Piercing Shot", "description": "Pistol rounds can hit one extra enemy. Pairs with Stone Lance.", "max_rank": 1},
	"channel": {"name": "Efficient Channel", "description": "Spell cooldowns are 6% shorter per rank, capped at 30% total reduction.", "max_rank": 3}}
const EVOLUTIONS := {
	"ember": {"name": "Wildfire Bolt", "pair": "focus", "description": "Rank 3 Ember Bolt also splashes 20% Power around its impact."},
	"frost": {"name": "Winter Halo", "pair": "vital", "description": "Rank 3 Frost Ring also shields 8% maximum HP for 3 seconds."},
	"chain": {"name": "Thunder Relay", "pair": "mechanic", "description": "Rank 3 Chain Spark gains a fourth jump at 15% Power."},
	"wisp": {"name": "Soul Lantern", "pair": "magnet", "description": "Rank 3 Orbiting Wisp circles farther out and adds 20% XP pickup reach."},
	"lance": {"name": "Rift Spear", "pair": "pierce", "description": "Rank 3 Stone Lance pierces two additional targets."},
	"ground": {"name": "Sanctuary", "pair": "vital", "description": "Your damage circle also heals 0.5% maximum HP per second while you stand inside. Healing circles do not stack."},
	"blades": {"name": "Phantom Flurry", "pair": "quick", "description": "Each automatic volley gains one extra blade. Your chosen spread still applies."},
	"gravity": {"name": "Collapsed Star", "pair": "channel", "description": "After the pull, the knot bursts once for an additional 20% Power in its area."}}
const BRANCHES := {
	"ember": {
		"focus": {"name": "Cinder Spear", "description": "+20% impact, pierces one extra foe. Burn is 25% weaker.", "damage": 1.2, "burn": 0.75, "count": 1, "pierce": 1},
		"spread": {"name": "Ember Volley", "description": "Two spreading bolts, each at 65% impact and burn. Aim through groups.", "damage": 0.65, "burn": 0.65, "count": 2}},
	"frost": {
		"focus": {"name": "Cold Snap", "description": "+30% damage, but radius shrinks from 150 to 115.", "damage": 1.3, "radius": 115.0},
		"spread": {"name": "Winter Reach", "description": "Radius grows from 150 to 190. Damage is 20% lower; chill stays effective.", "damage": 0.8, "radius": 190.0}},
	"chain": {
		"focus": {"name": "Charged Arc", "description": "First hit deals 35% more damage. Jump reach narrows from 180 to 140.", "first_damage": 1.35, "range": 140.0, "count": 3},
		"spread": {"name": "Forked Current", "description": "Adds a fourth jump. Every hit is 20% weaker.", "damage": 0.8, "range": 180.0, "count": 4}},
	"wisp": {
		"focus": {"name": "Hunting Wisp", "description": "+35% contact damage. Orbit tightens from 75 to 60.", "damage": 1.35, "radius": 60.0, "count": 1},
		"spread": {"name": "Twin Wisps", "description": "Two opposite wisps, each at 65% damage. They share the per-enemy hit limit.", "damage": 0.65, "radius": 75.0, "count": 2}},
	"lance": {
		"focus": {"name": "Obsidian Needle", "description": "+30% damage. Narrower aim and only two targets per cast.", "damage": 1.3, "width": 14.0, "hits": 2},
		"spread": {"name": "Stone Fan", "description": "Twice the line width. Three targets, each taking 20% less damage.", "damage": 0.8, "width": 40.0, "hits": 3}},
	"ground": {
		"focus": {"name": "Sanctum", "description": "+25% damage per second. Radius shrinks from 90 to 70.", "damage": 1.25, "radius": 70.0},
		"spread": {"name": "Beacon Field", "description": "Radius grows from 90 to 120. Damage per second is 25% lower.", "damage": 0.75, "radius": 120.0}},
	"blades": {
		"focus": {"name": "Spectral Daggers", "description": "Two faster blades with 20% more damage each. Normal attack reach.", "damage": 1.2, "count": 2, "speed": 650.0},
		"spread": {"name": "Fan of Knives", "description": "Three blades in a wide spread. Each deals 70% damage.", "damage": 0.7, "count": 3, "speed": 500.0}},
	"gravity": {
		"focus": {"name": "Crushing Knot", "description": "+50% impact, stronger pull. Radius shrinks from 130 to 100.", "damage": 1.5, "radius": 100.0, "pull": 90.0},
		"spread": {"name": "Wide Orbit", "description": "Radius grows from 130 to 170. Damage is 25% lower; pull is gentler.", "damage": 0.75, "radius": 170.0, "pull": 55.0}}}
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
