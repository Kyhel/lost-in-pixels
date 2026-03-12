class_name AIRoot
extends Node

var current_tree
var current_goal

var tree_cache := {}

@export var update_interval := 0.3
var timer := 0.0

func update_ai(delta: float):

	# timer -= delta
	# if timer > 0:
	# 	return

	# timer = update_interval

	var new_goal = UtilityAI.choose_goal(self.get_parent())

	if new_goal != current_goal:
		current_goal = new_goal
		switch_behavior_tree(new_goal.behavior_tree)

	if current_tree:
		current_tree.tick(self.get_parent(), delta)

func switch_behavior_tree(tree_scene: PackedScene):

	if current_tree:
		current_tree.queue_free()

	current_tree = tree_scene.instantiate()

	add_child(current_tree)
