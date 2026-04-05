extends VBoxContainer

const SLOT_SIZE := Vector2(108, 36)
const STAY_DURATION_MS := 10_000

var _rows: Dictionary ## Creature -> TextureRect
var _died_cbs: Dictionary ## Creature -> Callable
var _command_menu: PopupMenu
var _command_target: Creature


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	EventManager.creature_tamed.connect(_on_creature_tamed)
	_command_menu = PopupMenu.new()
	_command_menu.add_item("Free", 0)
	_command_menu.add_item("Heel", 1)
	_command_menu.add_item("Stay", 2)
	_command_menu.id_pressed.connect(_on_command_menu_id_pressed)
	var host: Node = get_parent()
	if host != null:
		host.call_deferred("add_child", _command_menu)
	else:
		call_deferred("add_child", _command_menu)
	for node in get_tree().get_nodes_in_group(Groups.TAMED_CREATURES):
		if node is Creature:
			_add_creature(node as Creature)


func _on_creature_tamed(creature: Creature) -> void:
	_add_creature(creature)


func _add_creature(creature: Creature) -> void:
	if creature == null or not is_instance_valid(creature):
		return
	if creature.creature_data == null:
		return
	if _rows.has(creature):
		return

	var row := TextureRect.new()
	row.custom_minimum_size = SLOT_SIZE
	row.size = SLOT_SIZE
	row.texture = creature.creature_data.sprite
	row.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.gui_input.connect(_on_row_gui_input.bind(creature))
	add_child(row)
	_rows[creature] = row

	var cb := _on_tamed_creature_died.bind(creature)
	creature.died.connect(cb)
	_died_cbs[creature] = cb
	_fit_height.call_deferred()


func _on_tamed_creature_died(creature: Creature) -> void:
	if not _rows.has(creature):
		return
	var cb: Callable = _died_cbs.get(creature, Callable())
	if not cb.is_null() and creature.died.is_connected(cb):
		creature.died.disconnect(cb)
	_died_cbs.erase(creature)
	var row: TextureRect = _rows[creature]
	_rows.erase(creature)
	if is_instance_valid(row):
		row.queue_free()
	_fit_height.call_deferred()


func _fit_height() -> void:
	var sep := get_theme_constant(&"separation", &"VBoxContainer")
	var h := 0.0
	var idx := 0
	for row in _rows.values():
		if not is_instance_valid(row):
			continue
		if idx > 0:
			h += sep
		h += (row as Control).get_combined_minimum_size().y
		idx += 1
	offset_right = offset_left + SLOT_SIZE.x
	offset_bottom = offset_top + h


func _creature_supports_commands(creature: Creature) -> bool:
	if creature == null or not is_instance_valid(creature) or creature.creature_data == null:
		return false
	return creature.creature_data.id == &"fox"


# Callable.bind appends bound args after signal args (gui_input emits event first).
func _on_row_gui_input(event: InputEvent, creature: Creature) -> void:
	if not _creature_supports_commands(creature):
		return
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_RIGHT:
		return
	if _command_menu == null:
		return
	_command_target = creature
	_command_menu.position = Vector2i(get_global_mouse_position())
	_command_menu.popup()


func _on_command_menu_id_pressed(id: int) -> void:
	var creature := _command_target
	_command_target = null
	if creature == null or not is_instance_valid(creature):
		return
	if not creature.blackboard.get_value(Blackboard.KEY_TAMED, false):
		return
	match id:
		0:
			creature.blackboard.set_value(Blackboard.KEY_TAME_COMMAND, TameCommand.Kind.FREE)
			creature.blackboard.clear(Blackboard.KEY_STAY_END_TIME_MS)
		1:
			creature.blackboard.set_value(Blackboard.KEY_TAME_COMMAND, TameCommand.Kind.HEEL)
			creature.blackboard.clear(Blackboard.KEY_STAY_END_TIME_MS)
		2:
			creature.blackboard.set_value(Blackboard.KEY_TAME_COMMAND, TameCommand.Kind.STAY)
			creature.blackboard.set_value(
				Blackboard.KEY_STAY_END_TIME_MS,
				Time.get_ticks_msec() + STAY_DURATION_MS
			)
		_:
			pass
