extends PanelContainer


@onready var _grid: GridContainer = $GridContainer

var _popup: PopupMenu
var _context_slot: int = -1
var _context_actions: Dictionary = {}


func _ready() -> void:
	_popup = PopupMenu.new()
	add_child(_popup)
	_popup.id_pressed.connect(_on_popup_id_pressed)
	Inventory.inventory_changed.connect(_refresh)
	_connect_slots()
	_refresh()


func _connect_slots() -> void:
	for i in _grid.get_child_count():
		var cell: Control = _grid.get_child(i) as Control
		if cell == null:
			continue
		cell.gui_input.connect(_on_slot_gui_input.bind(i))


func _on_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	if not event is InputEventMouseButton:
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_RIGHT:
		return
	var data: Variant = Inventory.get_slot(slot_index)
	if data == null or not data is Dictionary:
		return
	var id: StringName = data["id"]
	var def: ItemData = ItemDatabase.get_item_data(id)
	if def == null:
		return
	var can_eat := def.get_food_amount() > 0.0
	var can_drop := def.on_drop_object != null
	if not can_eat and not can_drop:
		return
	_context_slot = slot_index
	_popup.clear()
	_context_actions.clear()
	var next_id := 0
	if can_eat:
		_popup.add_item("Eat", next_id)
		_context_actions[next_id] = "eat"
		next_id += 1
	if can_drop:
		_popup.add_item("Drop", next_id)
		_context_actions[next_id] = "drop"
		next_id += 1
	_popup.position = get_global_mouse_position()
	_popup.popup()


func _on_popup_id_pressed(menu_id: int) -> void:
	if _context_slot < 0:
		return
	var action: String = str(_context_actions.get(menu_id, ""))
	if action.is_empty():
		return
	var player: Player = get_tree().get_first_node_in_group(Groups.PLAYER) as Player
	if player == null:
		return
	if action == "eat":
		Inventory.consume_one_at_slot(_context_slot, player)
	elif action == "drop":
		Inventory.drop_one_at_slot(_context_slot, player)
	_context_slot = -1
	_context_actions.clear()


func _refresh() -> void:
	for i in _grid.get_child_count():
		var cell: Node = _grid.get_child(i)
		var tex_rect: TextureRect = cell.get_node("Center/Icon") as TextureRect
		var lbl: Label = cell.get_node("Count") as Label
		var data: Variant = Inventory.get_slot(i)
		if data == null or not data is Dictionary:
			tex_rect.texture = null
			lbl.text = ""
			continue
		var id: StringName = data["id"]
		var count: int = int(data["count"])
		var def: ItemData = ItemDatabase.get_item_data(id)
		tex_rect.texture = def.texture if def != null else null
		lbl.text = str(count)
