extends VBoxContainer

const SLOT_SIZE := Vector2(108, 36)
const STAY_DURATION_MS := 10_000

@export var creature_slot_scene: PackedScene

var _rows: Dictionary ## Creature -> TamedCreatureSlot
var _died_cbs: Dictionary ## Creature -> Callable
var _bb_cbs: Dictionary ## Creature -> Callable
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

	var row := creature_slot_scene.instantiate() as TamedCreatureSlot
	row.mouse_filter = Control.MOUSE_FILTER_STOP
	row.gui_input.connect(_on_row_gui_input.bind(creature))
	add_child(row)
	row.portrait.texture = creature.creature_data.sprite

	var cmd_lbl := row.command_label

	_apply_command_label(creature, cmd_lbl)

	var bb_cb := _on_creature_blackboard_changed.bind(creature, cmd_lbl)
	creature.blackboard.value_changed.connect(bb_cb)
	_bb_cbs[creature] = bb_cb

	_rows[creature] = row

	var cb := _remove_creature.bind(creature)
	creature.died.connect(cb)
	_died_cbs[creature] = cb
	_fit_height.call_deferred()


func _command_label_text(creature: Creature) -> String:
	var cmd: int = int(creature.blackboard.get_value(Blackboard.KEY_TAME_COMMAND, TameCommand.Kind.FREE))
	match cmd:
		TameCommand.Kind.FREE:
			return "Free"
		TameCommand.Kind.HEEL:
			return "Heel"
		TameCommand.Kind.STAY:
			return "Stay"
	return "Unknown"


func _apply_command_label(creature: Creature, label: Label) -> void:
	if not _creature_supports_commands(creature):
		label.visible = false
		return
	label.visible = true
	label.text = _command_label_text(creature)


func _on_creature_blackboard_changed(key: Variant, _value: Variant, creature: Creature, label: Label) -> void:
	if key != Blackboard.KEY_TAME_COMMAND:
		return
	_apply_command_label(creature, label)


func _remove_creature(creature: Creature) -> void:
	if not _rows.has(creature):
		return
	var bb_cb: Callable = _bb_cbs.get(creature)
	if not bb_cb.is_null() and creature.blackboard.value_changed.is_connected(bb_cb):
		creature.blackboard.value_changed.disconnect(bb_cb)
	_bb_cbs.erase(creature)
	var cb: Callable = _died_cbs.get(creature)
	if not cb.is_null() and creature.died.is_connected(cb):
		creature.died.disconnect(cb)
	_died_cbs.erase(creature)
	var row: TamedCreatureSlot = _rows[creature]
	_rows.erase(creature)
	if is_instance_valid(row):
		row.queue_free()
	_fit_height.call_deferred()


func _fit_height() -> void:
	var sep := get_theme_constant(&"separation", &"VBoxContainer")
	var h := 0.0
	var idx := 0
	var panel_w := SLOT_SIZE.x
	for row in _rows.values():
		if not is_instance_valid(row):
			continue
		if idx > 0:
			h += sep
		var slot: Control = row
		h += slot.get_combined_minimum_size().y
		if idx == 0:
			panel_w = slot.custom_minimum_size.x
		idx += 1
	offset_right = offset_left + panel_w
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
