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
	if tree_scene == null:
		return

	if current_tree:
		if current_tree.get_parent() == self:
			remove_child(current_tree)

	var cache_key: String = _get_tree_cache_key(tree_scene)
	var cached_tree = tree_cache.get(cache_key, null)
	var is_reused := false

	if cached_tree != null and is_instance_valid(cached_tree):
		current_tree = cached_tree
		is_reused = true
	else:
		current_tree = tree_scene.instantiate()
		tree_cache[cache_key] = current_tree

	if current_tree.get_parent() != self:
		add_child(current_tree)

	if is_reused and current_tree.has_method("reset"):
		current_tree.reset()

func _get_tree_cache_key(tree_scene: PackedScene) -> String:
	var path: String = tree_scene.resource_path
	if path.is_empty():
		# Fallback for in-memory scenes with no resource path.
		return "instance_%s" % tree_scene.get_instance_id()
	return path

func on_goal_changed(old_goal: Goal, new_goal: Goal):

	if old_goal != null and old_goal.has_tag(GoalTags.TAG_FOLLOW_PLAYER):
		creature.remove_from_group(Constants.GROUP_FOLLOWING_CREATURES)

	if new_goal != null and new_goal.has_tag(GoalTags.TAG_FOLLOW_PLAYER):
		creature.add_to_group(Constants.GROUP_FOLLOWING_CREATURES)
