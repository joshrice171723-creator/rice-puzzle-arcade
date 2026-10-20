extends RefCounted
## Rigid limb segments bend at joints; stance feet travel backward at world speed.

static func foot(phase: float, travel: Vector2, stride_length: float, lift: float) -> Vector2:
	var cycle := fposmod(phase/TAU,1.0)
	if cycle < 0.55:
		return travel*lerpf(stride_length*0.5,-stride_length*0.5,cycle/0.55)
	var swing := (cycle-0.55)/0.45
	return travel*lerpf(-stride_length*0.5,stride_length*0.5,smoothstep(0,1,swing))+Vector2(0,-sin(swing*PI)*lift)

static func knee(hip: Vector2, ankle: Vector2, upper_length: float, lower_length: float, bend: float) -> Vector2:
	var axis := ankle-hip
	var distance := clampf(axis.length(),0.001,(upper_length+lower_length)*0.999)
	var direction := axis.normalized() if axis.length_squared()>0.000001 else Vector2.DOWN
	var reach := (upper_length*upper_length-lower_length*lower_length+distance*distance)/(2*distance)
	var height := sqrt(maxf(0,upper_length*upper_length-reach*reach))
	return hip+direction*reach+direction.orthogonal()*height*bend

static func bone(point: Vector2, from: Vector2, to: Vector2, target_from: Vector2, target_to: Vector2) -> Vector2:
	return target_from+(point-from).rotated((target_to-target_from).angle()-(to-from).angle())

static func leg(point: Vector2, hip: Vector2, rest_knee: Vector2, ankle: Vector2, hip_delta: Vector2, foot_delta: Vector2) -> Vector2:
	var target_hip := hip+hip_delta
	var target_ankle := ankle+foot_delta
	var bend := -1.0 if (ankle-hip).cross(rest_knee-hip)>0 else 1.0
	var target_knee := knee(target_hip,target_ankle,hip.distance_to(rest_knee),rest_knee.distance_to(ankle),bend)
	var upper := bone(point,hip,rest_knee,target_hip,target_knee)
	var lower := bone(point,rest_knee,ankle,target_knee,target_ankle)
	# Blend only across a narrow knee cuff, not over the entire silhouette.
	return upper.lerp(lower,smoothstep(rest_knee.y-1.5,rest_knee.y+1.5,point.y))

static func leg_bones(hip: Vector2, rest_knee: Vector2, ankle: Vector2, hip_delta: Vector2, foot_delta: Vector2) -> Array[Transform2D]:
	var target_hip := hip+hip_delta
	var target_ankle := ankle+foot_delta
	var bend := -1.0 if (ankle-hip).cross(rest_knee-hip)>0 else 1.0
	var target_knee := knee(target_hip,target_ankle,hip.distance_to(rest_knee),rest_knee.distance_to(ankle),bend)
	return [segment(hip,rest_knee,target_hip,target_knee),segment(rest_knee,ankle,target_knee,target_ankle),Transform2D(0,target_ankle-ankle)]

static func segment(from: Vector2, to: Vector2, target_from: Vector2, target_to: Vector2) -> Transform2D:
	var rotation := (target_to-target_from).angle()-(to-from).angle()
	return Transform2D(rotation,target_from-from.rotated(rotation))

static func torso(phase: float, blend: float, height: float) -> Vector2:
	return Vector2(0,(0.5-0.5*cos(phase*2.0))*height*0.012)*blend
