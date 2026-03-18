class_name MovementStrategy
extends Resource

@export var movement_type: CreatureData.MovementType = CreatureData.MovementType.DEFAULT

@export var separation_multiplier: float = 20
@export var neighbor_radius: float = 80.0

@export var avoid_distance: float = 100.0
@export var avoid_force: float = 200.0

@export var max_force: float = 1000.0

func move(_creature: Creature, _target_position: Vector2, _delta: float, _speed_multiplier: float) -> void:
	pass

func reset() -> void:
	pass

## Shared logic for directed movement: rotate toward target, then set velocity to direction × speed.
## Used by WalkStrategy, RunStrategy, and SprintStrategy.
func _move_toward_with_speed(creature: Creature, target_position: Vector2, delta: float, speed: float) -> void:
	if creature.creature_data == null:
		return
	var dir = (target_position - creature.global_position).normalized()
	var target_angle := dir.angle()
	var angle_diff := angle_difference(creature.virtual_rotation, target_angle)
	var angle_diff_abs: float = abs(angle_diff)
	var max_turn := creature.creature_data.rotating_speed * delta
	creature.virtual_rotation += sign(angle_diff) * min(angle_diff_abs, max_turn)

	var desired_velocity = dir * speed

	# desired_velocity = compute_velocity(creature, target_position, delta, speed, desired_velocity)

	creature.velocity = desired_velocity

func compute_velocity(creature, target_position: Vector2, delta: float, speed: float, velocity: Vector2) -> Vector2:
	
	var seek = _seek(creature, target_position, speed)
	var separation = _compute_separation(creature) * 1.5
	var avoidance = _obstacle_avoidance(creature, velocity) * 2.0

	var steering = seek + separation + avoidance
	steering = steering.limit_length(max_force)

	velocity += steering * delta
	velocity = velocity.limit_length(speed)

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
	
	var force = Vector2.ZERO
	var count = 0
	
	for other in creature.get_tree().get_nodes_in_group(Constants.GROUP_FOLLOWING_CREATURES):

		if !is_instance_valid(other):
			continue

		if other == creature:
			continue

		var to = creature.global_position - other.global_position
		var dist = to.length()

		if dist > 0 and dist < separation_multiplier * creature.creature_data.hitbox_size:
			force += to.normalized() / dist
			count += 1

	if count > 0:
		force /= count
	
	return force

func _obstacle_avoidance(creature: Creature, velocity: Vector2) -> Vector2:
	
	var space = creature.get_world_2d().direct_space_state
	
	if velocity.length() < 5:
		return Vector2.ZERO
	
	var forward = velocity.normalized()
	var right = forward.rotated(PI / 4)
	var left  = forward.rotated(-PI / 4)
	
	var directions = [
		forward,
		(forward + right).normalized(),
		(forward + left).normalized()
	]
	
	var strongest_force = Vector2.ZERO
	var closest_dist = INF
	
	for dir in directions:
		var from = creature.global_position
		var to = from + dir * avoid_distance
		
		var result = space.intersect_ray(PhysicsRayQueryParameters2D.create(from, to, creature.collision_mask, [creature]))
		
		if result:
			var dist = from.distance_to(result.position)
			
			if dist < closest_dist:
				closest_dist = dist
				
				# steer away from surface
				var normal = result.normal
				
				# stronger when closer
				var strength = (avoid_distance - dist) / avoid_distance
				
				strongest_force = normal * strength * avoid_force
	
	return strongest_force

func _compute_obstacle_avoidance(creature):
	var space = creature.get_world_2d().direct_space_state
	
	var result = space.intersect_ray(
		PhysicsRayQueryParameters2D.create(
		creature.global_position,
		creature.global_position + creature.velocity.normalized() * creature.creature_data.hitbox_size * 2,
		creature.collision_mask,
		[creature]
	))
	
	if result:
		var normal = result.normal
		return normal * 2.0
	
	return Vector2.ZERO
