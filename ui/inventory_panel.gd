extends PanelContainer


@onready var _grid: GridContainer = $GridContainer


func _ready() -> void:
	Inventory.inventory_changed.connect(_refresh)
	_refresh()


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
