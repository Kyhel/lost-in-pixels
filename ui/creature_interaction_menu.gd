extends CanvasLayer

@onready var _main_panel: VBoxContainer = $Panel/MainVBox
@onready var _title: Label = $Panel/MainVBox/Title
@onready var _item_panel: VBoxContainer = $Panel/ItemVBox
@onready var _item_list: ItemList = $Panel/ItemVBox/ItemList


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	_item_panel.visible = false
	_item_list.item_selected.connect(_on_item_selected)


func open_for_creature(creature: Creature) -> void:
	visible = true
	_main_panel.visible = true
	_item_panel.visible = false
	if creature != null and creature.creature_data != null and not creature.creature_data.display_name.is_empty():
		_title.text = creature.creature_data.display_name
	else:
		_title.text = "Creature"


func hide_menu() -> void:
	visible = false
	_item_panel.visible = false


func _on_give_item_pressed() -> void:
	var has_any := false
	for i in Inventory.SLOT_COUNT:
		var entry: Variant = Inventory.get_slot(i)
		if entry != null and entry is Dictionary and int(entry.get("count", 0)) > 0:
			has_any = true
			break
	if not has_any:
		return
	_refresh_item_list()
	_main_panel.visible = false
	_item_panel.visible = true


func _on_back_pressed() -> void:
	_item_panel.visible = false
	_main_panel.visible = true


func _on_pet_pressed() -> void:
	var c: Creature = PlayerCreatureInteractionSystem.get_target_creature()
	if c == null:
		return
	PlayerCreatureInteractionSystem.player_pet_creature(c)
	PlayerCreatureInteractionSystem.end_interaction()


func _refresh_item_list() -> void:
	_item_list.clear()
	for i in Inventory.SLOT_COUNT:
		var entry: Variant = Inventory.get_slot(i)
		if entry == null or not entry is Dictionary:
			continue
		var id: StringName = entry["id"]
		var count: int = int(entry["count"])
		if count <= 0:
			continue
		var def: ItemData = ItemDatabase.get_item_data(id)
		var label := def.display_name if def != null else String(id)
		var idx: int = _item_list.add_item("%s x%d" % [label, count])
		_item_list.set_item_metadata(idx, id)


func _on_item_selected(index: int) -> void:
	var id: Variant = _item_list.get_item_metadata(index)
	if id == null:
		return
	var c: Creature = PlayerCreatureInteractionSystem.get_target_creature()
	if c == null:
		return
	PlayerCreatureInteractionSystem.creature_receive_item_from_player(c, id as StringName)
	PlayerCreatureInteractionSystem.end_interaction()
