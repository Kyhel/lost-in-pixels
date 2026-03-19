class_name MovementStrategy
extends Resource

const NO_MOVEMENT_DIRECTION_THRESHOLD: float = PI / 2

@export var movement_type: CreatureData.MovementType = CreatureData.MovementType.DEFAULT

var separation_multiplier: float = 2
var separation_force: float = 100.0

var avoid_distance: float = 100.0
var avoid_force: float = 70.0

var max_force: float = 1000.0

func move(_creature: Creature, _target_position: Vector2, _delta: float, _speed_multiplier: float) -> void:
	pass

func reset() -> void:
	pass

## Shared logic for directed movement: rotate toward target, then set velocity to direction × speed.
## Used by WalkStrategy, RunStrategy, and SprintStrategy.
func _move_toward_with_speed(creature: Creature, target_position: Vector2, _delta: float, speed: float) -> void:

	if creature.creature_data == null:
		return

	var dir = (target_position - creature.global_position).normalized()
	var desired_velocity = dir * speed

	desired_velocity = compute_velocity(creature, target_position, speed, desired_velocity)
	
	# Limit the rotation speed to the creature's rotating speed.
	var target_angle := desired_velocity.angle()
	var angle_diff := angle_difference(creature.virtual_rotation, target_angle)
	var angle_diff_abs: float = abs(angle_diff)
	var max_turn := creature.creature_data.rotating_speed * _delta

	# Limit the speed based on the angle difference between the desired velocity and the creature's virtual rotation.
	var rotation_ratio = (NO_MOVEMENT_DIRECTION_THRESHOLD - angle_diff_abs) / NO_MOVEMENT_DIRECTION_THRESHOLD

	creature.virtual_rotation += sign(angle_diff) * min(angle_diff_abs, max_turn)
	creature.velocity = Vector2.from_angle(creature.virtual_rotation) * desired_velocity.length() * rotation_ratio;

func compute_velocity(creature, target_position: Vector2, speed: float, velocity: Vector2) -> Vector2:
	
	var seek = _seek(creature, target_position, speed)
	var separation = _compute_separation(creature) * 1.5
	var avoidance = _obstacle_avoidance(creature, velocity) * 2.0

	var steering = seek
	steering += separation
	steering += avoidance

	# Debug values (drawn by the creature scene).
	if creature != null:
		creature.debug_seek = seek
		creature.debug_separation = separation
		creature.debug_avoidance = avoidance
		creature.debug_steering = steering

	velocity += steering
	velocity = velocity.limit_length(speed)
	if creature != null:
		creature.debug_final_velocity = velocity

	return velocity

func _seek(creature: Creature, target_position: Vector2, max_speed: float) -> Vector2:
	var desired = target_position - creature.global_position
	var distance = desired.length()
	
	if distance == 0:
		return Vector2.ZERO
	
	# Arrival behavior (important!)
	var speed := max_speed
	if distance < 50:
		speed *= distance / 50.0
	
	desired = desired.normalized() * speed

	return desired

func _compute_separation(creature: Creature) -> Vector2:

	var separation_radius = separation_multiplier * creature.creature_data.hitbox_size
	
	var force = Vector2.ZERO
	var count = 0
	
	for other in creature.get_tree().get_nodes_in_group(Constants.GROUP_FOLLOWING_CREATURES):

		if !is_instance_valid(other):
			continue

		if other == creature:
			continue

		var to = creature.global_position - other.global_position
		var dist = to.length()

		if dist > 0 and dist < separation_radius:
			var force_strength = (separation_radius - dist) / separation_radius
			force += to.normalized() * force_strength
			count += 1

	if count > 0:
		force /= count
	
	return force

func _obstacle_avoidance(creature: Creature, velocity: Vector2) -> Vector2:
	# Sweep the creature's collision shape along [velocity] so we see every overlapping
	# obstacle in that corridor (rays only return the single closest hit per ray).
	var space: PhysicsDirectSpaceState2D = creature.get_world_2d().direct_space_state
	if space == null:
		return Vector2.ZERO
	if creature.creature_data == null:
		return Vector2.ZERO
	if velocity.length() < 5.0:
		return Vector2.ZERO

	var shape_node: CollisionShape2D = creature.collisionShape
	if shape_node == null or shape_node.shape == null:
		return Vector2.ZERO

	var forward: Vector2 = velocity.normalized()
	var sweep_len: float = avoid_distance

	# Sample positions along the motion so the union of shape queries approximates a swept hitbox.
	var min_step: float = maxf(8.0, creature.creature_data.hitbox_size * 0.25)
	var step_count: int = maxi(3, ceili(sweep_len / min_step))
	step_count = mini(step_count, 16)

	var base_xform: Transform2D = shape_node.global_transform

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = shape_node.shape
	params.collision_mask = creature.collision_mask
	params.collide_with_bodies = true
	params.collide_with_areas = false
	params.exclude = [creature.get_rid()]

	# instance_id -> closest distance (creature center to obstacle center) seen during sweep
	var obstacle_best_dist: Dictionary = {}

	for step in range(step_count):
		var t: float = 0.0
		if step_count > 1:
			t = sweep_len * float(step) / float(step_count - 1)
		var offset: Vector2 = forward * t
		params.transform = Transform2D(base_xform.x, base_xform.y, base_xform.origin + offset)

		var results: Array = space.intersect_shape(params, 32)
		for res in results:
			var collider: Object = res.get("collider", null)
			if collider == null or not is_instance_valid(collider) or collider == creature:
				continue
			if not (collider is Node2D):
				continue

			# Dont try to avoid the target food.
			if collider == creature.blackboard.get_value(Blackboard.KEY_TARGET_FOOD):
				continue

			var other: Node2D = collider as Node2D
			var dist: float = creature.global_position.distance_to(other.global_position)
			var cid: int = collider.get_instance_id()
			if not obstacle_best_dist.has(cid):
				obstacle_best_dist[cid] = dist
			else:
				obstacle_best_dist[cid] = minf(obstacle_best_dist[cid] as float, dist)

	var total_force := Vector2.ZERO
	for cid_key in obstacle_best_dist:
		var cid: int = int(cid_key)
		var collider: Object = instance_from_id(cid)
		if collider == null or not is_instance_valid(collider) or not (collider is Node2D):
			continue
		var other: Node2D = collider as Node2D
		var dist: float = obstacle_best_dist[cid_key] as float

		var hit_dir: Vector2 = other.global_position - creature.global_position
		if hit_dir.length_squared() < 0.0001:
			continue
		hit_dir = hit_dir.normalized()

		var perp := Vector2(-hit_dir.y, hit_dir.x)
		var side: float = sign(forward.cross(hit_dir))
		if side == 0.0:
			side = 1.0

		var strength: float = clampf((avoid_distance - dist) / avoid_distance, 0.0, 1.0)
		if strength <= 0.0:
			continue

		total_force += (-perp * side) * strength * avoid_force

	return total_force
