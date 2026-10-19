extends RefCounted
## Ground footprints for the visible altar plinths and caches, independent of tall artwork.

static func move_body(sites: Array, start: Vector2, finish: Vector2, radius: float, steer: float = 0.0) -> Vector2:
	var distance := start.distance_to(finish)
	var steps := maxi(1,ceili(distance/8.0))
	var step := (finish-start)/steps
	var position := start
	for index in steps:
		var candidate := position+step
		for site: Dictionary in sites:
			var cache: bool = site.kind == "cache"
			var center: Vector2 = site.pos+Vector2(0,-5 if cache else -15)
			var axes := Vector2(16,10) if cache else Vector2(58,32)
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
		position = candidate
	return position
