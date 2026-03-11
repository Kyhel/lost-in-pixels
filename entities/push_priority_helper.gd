class_name PushPriorityHelper

## Reusable push priority: after move_and_slide(), call [method apply_after_slide] so that
## same priority cannot push each other, and higher priority can push lower.
## Use with [CreatureData.push_priority] and/or a [code]push_priority[/code] property on the body.


## Returns the push priority of a node, or -1 if it does not participate in push priority.
## Supports: nodes with a [code]push_priority[/code] property; [Creature] with [CreatureData.push_priority].
static func get_push_priority(node: Node) -> int:
	if node == null:
		return -1
	if "push_priority" in node:
		return node.push_priority
	if node is Creature and (node as Creature).creature_data != null:
		return (node as Creature).creature_data.push_priority
	return -1


## Call after move_and_slide() on [param body]. Reverts [param body] to [param pos_before] if it
## collided with another body that has same or higher push priority (so only higher priority can push).
static func apply_after_slide(body: CharacterBody2D, my_priority: int, pos_before: Vector2) -> void:
	for i in body.get_slide_collision_count():
		var col := body.get_slide_collision(i)
		var other = col.get_collider()
		var other_priority := get_push_priority(other)
		if other_priority >= 0 and other_priority >= my_priority:
			body.global_position = pos_before
			return
