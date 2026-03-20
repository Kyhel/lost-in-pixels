class_name AIRoot
extends Node

var current_tree
var current_goal

var tree_cache := {}

@export var update_interval := 0.2
var _ai_elapsed := 0.0

var creature: Creature

func _ready():
	creature = get_parent()
	# Stagger AI updates so creatures do not all tick on the same frame.
	var phase: float = CreatureUtils.get_stagger_phase_offset(creature, update_interval)
	_ai_elapsed = -phase

func update_ai(delta: float):
	if update_interval <= 0.0:
		_run_ai(delta)
		return

	_ai_elapsed += delta
	if _ai_elapsed < update_interval:
		return

	var ai_delta := _ai_elapsed
	_ai_elapsed = fmod(_ai_elapsed, update_interval)
	_run_ai(ai_delta)

func _run_ai(delta: float) -> void:

	var new_goal = UtilityAI.choose_goal(creature)

	if new_goal != current_goal:
		on_goal_changed(current_goal, new_goal)
		current_goal = new_goal
		switch_behavior_tree(new_goal.behavior_tree)

	if current_tree:
		current_tree.tick(self.get_parent(), delta)

func switch_behavior_tree(tree_scene: PackedScene):

	if current_tree:
		current_tree.queue_free()

	current_tree = tree_scene.instantiate()

	add_child(current_tree)

func on_goal_changed(old_goal: Goal, new_goal: Goal):

	if old_goal != null and old_goal.has_tag(GoalTags.TAG_FOLLOW_PLAYER):
		creature.remove_from_group(Constants.GROUP_FOLLOWING_CREATURES)

	if new_goal != null and new_goal.has_tag(GoalTags.TAG_FOLLOW_PLAYER):
		creature.add_to_group(Constants.GROUP_FOLLOWING_CREATURES)
