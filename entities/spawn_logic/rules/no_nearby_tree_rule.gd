extends SpawnRule
class_name NoNearbyTreeRule

@export var radius: int = 5

var tree_data: ItemData = ItemDatabase.get_item(&"tree")

func can_spawn(world_pos: Vector2, _context: Dictionary) -> bool:
    var nearby_items:= ObjectsManager.get_nearby_items(world_pos, radius * ChunkManager.TILE_SIZE)
    for item in nearby_items:
        if item.item_data == tree_data:
            return false
    return true
