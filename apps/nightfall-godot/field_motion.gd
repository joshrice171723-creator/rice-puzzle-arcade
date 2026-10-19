extends RefCounted
## Ground footprints for the visible altar plinths and caches, independent of tall artwork.
const Neighborhood = preload("res://neighborhood.gd")
const World = preload("res://world_geometry.gd")

static func move_body(sites: Array, start: Vector2, finish: Vector2, radius: float, steer: float = 0.0) -> Vector2:
	var distance := start.distance_to(finish)
	var steps := maxi(1,ceili(distance/8.0))
	var step := (finish-start)/steps
	var position := start
	for index in steps:
		var candidate := (position+step).clamp(World.BOUNDS.position,World.BOUNDS.end)
		for site: Dictionary in sites:
			var cache: bool = site.kind == "cache"
			var center: Vector2 = site.pos+Vector2(0,-5 if cache else 0)
			var axes := Vector2(16,10) if cache else Vector2(130,50)
			axes += Vector2.ONE*radius
			var local := (candidate-center)/axes
			if local.length_squared() >= 1.0:
				continue
			var normal := local.normalized()
			if normal == Vector2.ZERO:
				normal = ((position-center)/axes).normalized()
			if normal == Vector2.ZERO:
				normal = Vector2.DOWN
			if steer != 0 and distance > 0:
				# Give pursuing AI a stable side around a solid landmark, not a jittering retry.
				var tangent := (normal/axes).orthogonal().normalized()*steer
				normal = (normal+tangent*step.length()/axes).normalized()
			candidate = center+normal*axes
		for entry: Dictionary in Neighborhood.entries():
			var solid: Rect2 = entry.footprint.grow(radius)
			if not solid.has_point(candidate):
				continue
			var projections := [Vector2(solid.position.x-0.1,candidate.y),Vector2(solid.end.x+0.1,candidate.y),Vector2(candidate.x,solid.position.y-0.1),Vector2(candidate.x,solid.end.y+0.1)]
			var edge := -1
			var shortest := INF
			for side in projections.size():
				var projected: Vector2 = projections[side].clamp(World.BOUNDS.position,World.BOUNDS.end)
				# An edge outside the world cannot be an escape: final clamping would
				# put the body back in the building, including migrated checkpoints.
				if solid.has_point(projected):
					continue
				var separation := candidate.distance_squared_to(projected)
				if separation < shortest:
					shortest = separation
					edge = side
					projections[side] = projected
			if edge < 0:
				continue
			candidate = projections[edge]
			if steer != 0 and distance > 0:
				# Stable wall following lets pursuing enemies round buildings instead of stalling.
				if edge < 2: candidate.y += step.length()*steer
				else: candidate.x += step.length()*steer
		position = candidate
	return position
