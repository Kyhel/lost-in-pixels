class_name MovementStrategy
extends Resource

const NO_MOVEMENT_DIRECTION_THRESHOLD: float = PI / 2

var separation_multiplier: float = 2
var separation_force: float = 100.0

var avoid_distance: float = 200.0
## Lookahead time (s): sweep length uses [min](speed × this, [member avoid_distance]).
var avoid_lookahead_seconds: float = 1.0
var avoid_force: float = 70.0

var max_force: float = 1000.0

func move(_creature: Creature, _request: MovementRequest, _delta: float) -> void:
	pass

func reset() -> void:
	pass


const MAX_PREDICTION_TIME: float = 3.0


func _estimate_chaser_speed(creature: Creature) -> float:
	if creature.creature_data == null:
		return 0.0
	return creature.creature_data.base_speed * creature.creature_data.running_multiplier


## Constant-velocity intercept: smallest positive [t] with |P + V*t - C| ≈ v_c * t (same-speed pursuit path).
func _predict_approach_target_position(creature: Creature, approach: Node2D, chaser_speed: float) -> Vector2:
	if not (approach is CharacterBody2D):
		return approach.global_position
	if chaser_speed < 1.0:
		return approach.global_position
	var target_body: CharacterBody2D = approach as CharacterBody2D
	var v: Vector2 = target_body.velocity
	if v.length_squared() < 0.04:
		return approach.global_position
	var P: Vector2 = approach.global_position
	var C: Vector2 = creature.global_position
	var R: Vector2 = P - C
	var vv: float = v.dot(v)
	var vcs: float = chaser_speed * chaser_speed
	var a: float = vv - vcs
	var b: float = 2.0 * R.dot(v)
	var c: float = R.dot(R)
	var t: float = -1.0
	if absf(a) < 0.000001:
		if absf(b) > 0.000001:
			t = -c / b
	else:
		var disc: float = b * b - 4.0 * a * c
		if disc >= 0.0:
			var s: float = sqrt(disc)
			var t0: float = (-b - s) / (2.0 * a)
			var t1: float = (-b + s) / (2.0 * a)
			var best_t: float = -1.0
			for bt in [t0, t1]:
				if bt > 0.0:
					if best_t < 0.0 or bt < best_t:
						best_t = bt
			t = best_t
	if t <= 0.0 or t > MAX_PREDICTION_TIME:
		return P
	return P + v * t


## [chaser_speed] is the speed magnitude used for intercept math (pass strategy speed, or negative to estimate).
func _resolve_request_kinematics(creature: Creature, request: MovementRequest, chaser_speed: float = -1.0) -> Dictionary:
	if chaser_speed < 0.0:
		chaser_speed = _estimate_chaser_speed(creature)
	var move_goal: Vector2
	var face_point: Vector2
	var approach: Node2D = request.approach_target
	var thr: float = request.completion_distance_threshold
	var allow_translate: bool = true

	if approach != null and is_instance_valid(approach):
		var center_base: Vector2 = _predict_approach_target_position(creature, approach, chaser_speed)
		var r_c: float = creature.get_hitbox_radius()
		var r_t: float = Node2DUtils.get_target_radius_for_interaction(approach)

		var d_to_actual: float = creature.global_position.distance_to(approach.global_position)
		var seek_center: Vector2 = center_base
		if request.approach_spacing == MovementRequest.ApproachSpacing.INTERACTION:
			if d_to_actual < Constants.INTERACTION_CLOSE_BLEND_DISTANCE:
				seek_center = approach.global_position

		var anchor: Vector2 = seek_center + request.target_offset
		move_goal = anchor
		face_point = anchor
		match request.approach_spacing:
			MovementRequest.ApproachSpacing.INTERACTION:
				allow_translate = not Node2DUtils.is_within_interaction_range(creature, approach, Constants.INTERACTION_APPROACH_STOP_MARGIN)
				face_point = approach.global_position
			MovementRequest.ApproachSpacing.COMBAT:
				allow_translate = d_to_actual > r_c + r_t + Constants.DEFAULT_COMBAT_APPROACH_STANDOFF
				face_point = approach.global_position
			_:
				allow_translate = creature.global_position.distance_squared_to(move_goal) > thr * thr
	else:
		move_goal = request.target_position
		face_point = request.target_position
		allow_translate = creature.global_position.distance_squared_to(move_goal) > thr * thr
	return {
		"move_goal": move_goal,
		"face_point": face_point,
		"allow_translate": allow_translate,
	}

func _rotate_toward_angle(creature: Creature, target_angle: float, delta: float) -> void:
	if creature.creature_data == null:
		return
	var angle_diff := angle_difference(creature.virtual_rotation, target_angle)
	var angle_diff_abs: float = abs(angle_diff)
	var max_turn := creature.creature_data.rotating_speed * delta
	creature.virtual_rotation += sign(angle_diff) * min(angle_diff_abs, max_turn)

func _rotate_toward_world_point(creature: Creature, world_point: Vector2, delta: float) -> void:
	var to_t: Vector2 = world_point - creature.global_position
	if to_t.length_squared() < 0.0001:
		return
	_rotate_toward_angle(creature, to_t.angle(), delta)

## Shared logic for directed movement: rotate toward target, then set velocity to direction × speed.
## Used by RunStrategy and similar.
func _move_toward_with_speed(creature: Creature, request: MovementRequest, delta: float, speed: float) -> void:

	if creature.creature_data == null:
		return

	var k: Dictionary = _resolve_request_kinematics(creature, request, speed)
	if not k["allow_translate"]:
		creature.velocity = Vector2.ZERO
		if request.face_target:
			_rotate_toward_world_point(creature, k["face_point"], delta)
		return

	var move_goal: Vector2 = k["move_goal"]
	var pos_to_target := move_goal - creature.global_position
	var dir := pos_to_target
	if dir.length_squared() < 0.0001:
		creature.velocity = Vector2.ZERO
		if request.face_target:
			_rotate_toward_world_point(creature, k["face_point"], delta)
		return

	dir = dir.normalized()
	var desired_velocity = dir * speed

	desired_velocity = compute_velocity(creature, request, pos_to_target, speed, desired_velocity)
	
	# Limit the rotation speed to the creature's rotating speed.
	var target_angle := desired_velocity.angle()
	var angle_diff := angle_difference(creature.virtual_rotation, target_angle)
	var angle_diff_abs: float = abs(angle_diff)
	var max_turn: float = creature.creature_data.rotating_speed * delta

	# Limit the speed based on the angle difference between the desired velocity and the creature's virtual rotation.
	var rotation_ratio = (NO_MOVEMENT_DIRECTION_THRESHOLD - angle_diff_abs) / NO_MOVEMENT_DIRECTION_THRESHOLD

	creature.virtual_rotation += sign(angle_diff) * min(angle_diff_abs, max_turn)
	creature.velocity = Vector2.from_angle(creature.virtual_rotation) * desired_velocity.length() * rotation_ratio;

func compute_velocity(
	creature: Creature,
	request: MovementRequest,
	pos_to_target: Vector2,
	speed: float,
	velocity: Vector2
) -> Vector2:
	
	var seek = _seek(pos_to_target, speed)
	var separation = _compute_separation(creature) * 1.5
	var avoidance = _obstacle_avoidance(creature, request, velocity) * 2.0

	var steering = seek
	steering += separation
	steering += avoidance

	velocity += steering
	velocity = velocity.limit_length(speed)

	if creature != null:
		var dbg := creature.creature_debug
		if dbg != null:
			dbg.set_movement_debug(seek, separation, avoidance, steering, velocity)

	return velocity

func _seek(pos_to_target: Vector2, max_speed: float) -> Vector2:
	var dist_sq: float = pos_to_target.length_squared()
	if dist_sq < 1e-12:
		return Vector2.ZERO
	var distance: float = sqrt(dist_sq)
	var speed: float = max_speed
	if dist_sq < 2500.0:
		speed *= distance / 50.0
	return pos_to_target * (speed / distance)

func _compute_separation(creature: Creature) -> Vector2:

	var separation_radius: float = separation_multiplier * creature.creature_data.hitbox_size
	var radius_sq: float = separation_radius * separation_radius

	var force := Vector2.ZERO
	var count := 0

	for other in creature.get_tree().get_nodes_in_group(Groups.FOLLOWING_CREATURES):

		if !is_instance_valid(other):
			continue

		if other == creature:
			continue

		var to: Vector2 = creature.global_position - other.global_position
		var dist_sq: float = to.length_squared()
		if dist_sq > 0.0 and dist_sq < radius_sq:
			var dist: float = sqrt(dist_sq)
			var force_strength: float = (separation_radius - dist) / separation_radius
			force += (to / dist) * force_strength
			count += 1

	if count > 0:
		force /= count

	return force

func _obstacle_avoidance(creature: Creature, request: MovementRequest, velocity: Vector2) -> Vector2:
	# Single oriented rectangle along intended velocity: length ≈ speed×lookahead (capped), width ≈ hitbox.
	var space: PhysicsDirectSpaceState2D = creature.get_world_2d().direct_space_state
	if space == null:
		return Vector2.ZERO
	if creature.creature_data == null:
		return Vector2.ZERO
	if velocity.length_squared() < 25.0:
		return Vector2.ZERO

	var shape_node: CollisionShape2D = creature.collisionShape
	if shape_node == null:
		return Vector2.ZERO

	var speed_mag: float = velocity.length()
	var sweep_len: float = minf(speed_mag * avoid_lookahead_seconds, avoid_distance)
	sweep_len = maxf(sweep_len, 1.0)

	var forward: Vector2 = velocity / speed_mag
	var hitbox: float = creature.creature_data.hitbox_size

	var corridor_origin: Vector2 = shape_node.global_position
	var center: Vector2 = corridor_origin + forward * (sweep_len * 0.5)
	var basis_y: Vector2 = Vector2(-forward.y, forward.x)
	var corridor_xform: Transform2D = Transform2D(forward, basis_y, center)

	var params: PhysicsShapeQueryParameters2D = creature.get_obstacle_avoidance_shape_query()
	params.shape.size = Vector2(sweep_len, hitbox)
	params.transform = corridor_xform
	params.collision_mask = creature.collision_mask
	params.exclude = [creature.get_rid()]

	var results: Array = space.intersect_shape(params, 32)
	var obstacle_best: Dictionary = {}

	for res in results:
		var collider: Object = res.get("collider", null)
		if collider == null or not is_instance_valid(collider) or collider == creature:
			continue
		if not (collider is Node2D):
			continue
		if _should_ignore_obstacle_for_current_target(collider, request, creature):
			continue

		var other: Node2D = collider as Node2D
		var dist: float = creature.global_position.distance_to(other.global_position)
		var cid: int = collider.get_instance_id()
		if not obstacle_best.has(cid):
			obstacle_best[cid] = {"dist": dist, "node": other}
		else:
			var prev: float = obstacle_best[cid]["dist"] as float
			if dist < prev:
				obstacle_best[cid]["dist"] = dist

	var total_force := Vector2.ZERO
	for cid_key in obstacle_best:
		var entry: Dictionary = obstacle_best[cid_key] as Dictionary
		var other: Node2D = entry["node"] as Node2D
		if other == null or not is_instance_valid(other):
			continue
		var dist: float = entry["dist"] as float

		var hit_dir: Vector2 = other.global_position - creature.global_position
		if hit_dir.length_squared() < 0.0001:
			continue
		hit_dir = hit_dir.normalized()

		var cross = forward.cross(hit_dir)

		var side := 1.0
		if cross < -0.035:
			side = -1.0

		var strength: float = clampf((sweep_len - dist) / sweep_len, 0.0, 1.0)
		if strength <= 0.0:
			continue

		var perp := Vector2(-hit_dir.y, hit_dir.x)

		total_force += (-perp * side) * strength * avoid_force

	return total_force


## Max center distance from [param eat_target] to [param obstacle] such that avoidance is skipped during [constant MovementRequest.MovementContext.EAT].
## Matches [method Node2DUtils.is_within_interaction_range] band (actor + target radii + [constant Constants.DEFAULT_INTERACTION_MARGIN]) plus obstacle extent so we do not steer away from things in the interaction neighborhood.
func _eat_interaction_neighborhood_max_dist(creature: Creature, eat_target: Node2D, obstacle: Node2D) -> float:
	var actor_r: float = creature.get_hitbox_radius()
	var target_r: float = Node2DUtils.get_target_radius_for_interaction(eat_target)
	var obstacle_r: float = Node2DUtils.get_target_radius_for_interaction(obstacle)
	return actor_r + target_r + Constants.DEFAULT_INTERACTION_MARGIN + obstacle_r


func _should_ignore_obstacle_for_current_target(collider: Object, request: MovementRequest, creature: Creature) -> bool:
	if request == null:
		return false
	if _should_ignore_chase_target_player(collider, request):
		return true
	var target: Node2D = request.approach_target
	if target == null or not is_instance_valid(target):
		return false
	if collider == target:
		return true
	if request.context != MovementRequest.MovementContext.EAT:
		return false
	if not (collider is Node2D):
		return false
	var obstacle: Node2D = collider as Node2D
	var max_d: float = _eat_interaction_neighborhood_max_dist(creature, target, obstacle)
	return target.global_position.distance_to(obstacle.global_position) <= max_d


func _should_ignore_chase_target_player(collider: Object, request: MovementRequest) -> bool:
	if request == null:
		return false
	if request.approach_target == null or request.approach_target != collider:
		return false
	if request.approach_spacing != MovementRequest.ApproachSpacing.COMBAT:
		return false
	if not (collider is Node):
		return false
	return (collider as Node).is_in_group(Groups.PLAYER)
