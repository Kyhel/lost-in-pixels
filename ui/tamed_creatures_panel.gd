extends VBoxContainer

const SLOT_SIZE := Vector2(108, 36)

var _rows: Dictionary ## Creature -> TextureRect
var _died_cbs: Dictionary ## Creature -> Callable


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	EventManager.creature_tamed.connect(_on_creature_tamed)
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
	for child in get_children():
		if child is Control:
			if idx > 0:
				h += sep
			h += (child as Control).get_combined_minimum_size().y
			idx += 1
	offset_right = offset_left + SLOT_SIZE.x
	offset_bottom = offset_top + h
