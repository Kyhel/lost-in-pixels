extends Control

const COLS := 4
const ROWS := 8
const CELL := 48
const PAD := 8

var _grid: GridContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var w := COLS * CELL + PAD * 2
	var h := ROWS * CELL + PAD * 2
	custom_minimum_size = Vector2(w, h)
	anchor_left = 1.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = -w - 16.0
	offset_right = -16.0
	offset_top = 16.0
	offset_bottom = 16.0 + h

	var bg := Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sbg := StyleBoxFlat.new()
	sbg.bg_color = Color(0.45, 0.45, 0.45, 0.5)
	bg.add_theme_stylebox_override(&"panel", sbg)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override(&"margin_left", PAD)
	margin.add_theme_constant_override(&"margin_right", PAD)
	margin.add_theme_constant_override(&"margin_top", PAD)
	margin.add_theme_constant_override(&"margin_bottom", PAD)
	add_child(margin)

	_grid = GridContainer.new()
	_grid.columns = COLS
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(_grid)

	for i in Inventory.SLOT_COUNT:
		_grid.add_child(_make_cell())

	Inventory.inventory_changed.connect(_refresh)
	_refresh()


func _make_cell() -> Control:
	var c := Panel.new()
	c.custom_minimum_size = Vector2(CELL, CELL)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.4, 0.4, 0.4, 0.35)
	style.set_border_width_all(1)
	style.border_color = Color(0.12, 0.12, 0.12, 1.0)
	c.add_theme_stylebox_override(&"panel", style)

	var center := CenterContainer.new()
	center.name = "Center"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.add_child(center)

	var tex := TextureRect.new()
	tex.name = "Icon"
	tex.custom_minimum_size = Vector2(36, 36)
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	center.add_child(tex)

	var lbl := Label.new()
	lbl.name = "Count"
	lbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	lbl.offset_left = -36.0
	lbl.offset_top = -20.0
	lbl.offset_right = -4.0
	lbl.offset_bottom = -2.0
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	lbl.add_theme_font_size_override(&"font_size", 12)
	c.add_child(lbl)
	return c


func _refresh() -> void:
	for i in _grid.get_child_count():
		var cell: Control = _grid.get_child(i) as Control
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
