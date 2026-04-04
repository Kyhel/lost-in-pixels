class_name AIRoot
extends Node

var current_tree
var current_goal

var tree_cache := {}

var creature: Creature

var _goal_commit_start_time_sec := 0.0

func _enter_tree() -> void:
	creature = get_parent() as Creature
	SimulationSystem.register_ai(
		self,
		func(_n: Object, td: float) -> void:
			_run_ai(td)
	)


func _run_ai(delta: float) -> void:

	var best: Goal = UtilityAI.choose_goal(creature)
	var now_sec := Time.get_ticks_msec() / 1000.0
	var should_switch := false

	if best != current_goal:
		if current_goal == null:
			should_switch = best != null
		elif best == null:
			should_switch = true
		else:
			var p_best: int = creature.get_goal_priority(best)
			var p_cur: int = creature.get_goal_priority(current_goal)
			var elapsed := now_sec - _goal_commit_start_time_sec
			should_switch = (p_best > p_cur) or (elapsed >= current_goal.commit_time)

	if should_switch:
		on_goal_changed(current_goal, best)
		current_goal = best
		_goal_commit_start_time_sec = now_sec
		if best != null:
			switch_behavior_tree(best.behavior_tree)
		else:
			_clear_behavior_tree()

	if current_tree:
		current_tree.tick(self.get_parent(), delta)

func _clear_behavior_tree() -> void:
	if current_tree == null:
		return
	if current_tree.get_parent() == self:
		remove_child(current_tree)
	current_tree = null


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
		creature.remove_from_group(Groups.FOLLOWING_CREATURES)

	if new_goal != null and new_goal.has_tag(GoalTags.TAG_FOLLOW_PLAYER):
		creature.add_to_group(Groups.FOLLOWING_CREATURES)
