extends RefCounted
## Shared authored scenery geometry. Rendering and collision consume the same data.
const BASE_SCENERY := [
	{"kind":"garage", "pos":Vector2(450,390), "draw_size":Vector2(380,352), "atlas_index":0, "footprint":Rect2(275,295,350,135)},
	{"kind":"house", "pos":Vector2(1880,460), "draw_size":Vector2(300,383), "atlas_index":1, "footprint":Rect2(1750,375,260,130)},
	{"kind":"garage", "pos":Vector2(1910,2180), "draw_size":Vector2(340,315), "atlas_index":0, "footprint":Rect2(1750,2090,320,130)},
	{"kind":"van", "pos":Vector2(420,2030), "draw_size":Vector2(310,260), "atlas_index":2, "footprint":Rect2(280,1950,280,120)},
	{"kind":"garage", "pos":Vector2(830,980), "draw_size":Vector2(240,222), "atlas_index":0, "footprint":Rect2(720,925,220,95)},
	{"kind":"van", "pos":Vector2(1460,1400), "draw_size":Vector2(210,176), "atlas_index":2, "footprint":Rect2(1365,1358,190,82)},
	{"kind":"house", "pos":Vector2(1520,1110), "draw_size":Vector2(320,408), "atlas_index":1, "footprint":Rect2(1390,1030,260,125)},
	{"kind":"streetlamp", "pos":Vector2(960,1120), "draw_size":Vector2(120,144), "detail_index":0, "footprint":Rect2(946,1106,28,28)},
	{"kind":"streetlamp", "pos":Vector2(1260,1530), "draw_size":Vector2(120,144), "detail_index":0, "footprint":Rect2(1246,1516,28,28)},
	{"kind":"fence", "pos":Vector2(1030,1490), "draw_size":Vector2(240,144), "detail_index":1, "footprint":Rect2(940,1460,180,60)},
	{"kind":"utility", "pos":Vector2(1620,1510), "draw_size":Vector2(85,140), "detail_index":2, "footprint":Rect2(1602,1495,36,30)},
	{"kind":"crates", "pos":Vector2(920,600), "draw_size":Vector2(150,97), "detail_index":3, "footprint":Rect2(855,555,130,65)},
	{"kind":"ruined_wall", "pos":Vector2(1880,950), "draw_size":Vector2(230,98), "detail_index":4, "footprint":Rect2(1780,920,200,65)},
	{"kind":"fence", "pos":Vector2(480,1330), "draw_size":Vector2(240,144), "detail_index":1, "footprint":Rect2(390,1300,180,60)}
]

const GROUNDCOVER := [Vector2(350,430),Vector2(610,425),Vector2(1700,475),Vector2(2010,490),Vector2(760,1000),Vector2(940,1020),Vector2(1350,1120),Vector2(1640,1140),Vector2(1360,1440),Vector2(1550,1430),Vector2(970,1510),Vector2(1110,1515),Vector2(1580,1540),Vector2(940,635),Vector2(1770,980),Vector2(1980,990),Vector2(400,1370),Vector2(565,1370),Vector2(310,2060),Vector2(535,2070),Vector2(1770,2200),Vector2(2020,2210)]

static var scenery: Array[Dictionary] = []
static var cover := PackedVector2Array()

static func entries() -> Array:
	if not scenery.is_empty():
		return scenery
	for original in BASE_SCENERY:
		var entry: Dictionary = original.duplicate()
		entry.pos = original.pos*2.5
		entry.footprint = Rect2(entry.pos+(original.footprint.position-original.pos),original.footprint.size)
		scenery.append(entry)
	for extra in [
		{"kind":"house","pos":Vector2(2700,2880),"draw_size":Vector2(300,383),"atlas_index":1,"footprint":Rect2(2570,2795,260,130)},
		{"kind":"van","pos":Vector2(3330,3250),"draw_size":Vector2(230,193),"atlas_index":2,"footprint":Rect2(3225,3200,210,90)},
		{"kind":"streetlamp","pos":Vector2(2780,3180),"draw_size":Vector2(120,144),"detail_index":0,"footprint":Rect2(2766,3166,28,28)},
		{"kind":"fence","pos":Vector2(2820,3330),"draw_size":Vector2(240,144),"detail_index":1,"footprint":Rect2(2730,3300,180,60)},
		{"kind":"utility","pos":Vector2(3340,2800),"draw_size":Vector2(85,140),"detail_index":2,"footprint":Rect2(3322,2785,36,30)},
		{"kind":"crates","pos":Vector2(3170,2620),"draw_size":Vector2(150,97),"detail_index":3,"footprint":Rect2(3105,2575,130,65)}]:
		scenery.append(extra)
	return scenery

static func groundcover() -> PackedVector2Array:
	if cover.is_empty():
		for entry in entries():
			var width: float = entry.draw_size.x*0.4
			cover.append(entry.pos+Vector2(-width,25))
			cover.append(entry.pos+Vector2(width,35))
	return cover
