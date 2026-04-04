class_name ItemData
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export var description: String = ""
@export var texture: Texture2D
@export var consume_effects: Array[Resource] = []
@export var on_drop_object: ObjectData


func get_food_amount() -> float:
	var total: float = 0.0
	for e in consume_effects:
		if e == null:
			continue
		var scr: Script = e.get_script() as Script
		if scr != null and scr.resource_path.ends_with("food_effect.gd"):
			total += float(e.get("amount"))
	return total

