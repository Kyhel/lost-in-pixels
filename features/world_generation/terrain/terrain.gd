extends Node
class_name Terrain

enum Type {
	NONE,
	WATER,
	SAND,
	GRASS,
	DARK_GRASS,
	SNOW,
	LAVA,
	TOXIC,
	BEACH,
	DEAD,
	SWAMP,
	TUNDRA,
	DANGER_COLD_DRY,
	DANGER_COLD_MOIST,
}

static var _tileDefinitions: Dictionary[Type, TerrainDefinition] = {
	Type.NONE: TerrainDefinition.new(Vector2i(0, 0), false, false, 0),
	Type.WATER: TerrainDefinition.new(Vector2i(2, 0), false, true, 0.5),
	Type.BEACH: TerrainDefinition.new(Vector2i(3, 0), true, false, 0.6),
	Type.SNOW: TerrainDefinition.new(Vector2i(4, 0), true, false, 0.5),
	Type.SWAMP: TerrainDefinition.new(Vector2i(0, 1), true, false, 1.0),
	Type.TUNDRA: TerrainDefinition.new(Vector2i(1, 1), true, false, 1.0),
	Type.GRASS: TerrainDefinition.new(Vector2i(2, 1), true, false, 1.0),
	Type.DARK_GRASS: TerrainDefinition.new(Vector2i(3, 1), true, false, 1.0),
	Type.SAND: TerrainDefinition.new(Vector2i(4, 1), true, false, 0.6),
	Type.DANGER_COLD_MOIST: TerrainDefinition.new(Vector2i(0, 2), true, false, 1.0),
	Type.DANGER_COLD_DRY: TerrainDefinition.new(Vector2i(1, 2), true, false, 1.0),
	Type.DEAD: TerrainDefinition.new(Vector2i(2, 2), true, false, 1.0),
	Type.TOXIC: TerrainDefinition.new(Vector2i(3, 2), true, false, 1.0),
	Type.LAVA: TerrainDefinition.new(Vector2i(4, 2), true, false, 1.0),
}


static func get_definition(tile_type: Type) -> TerrainDefinition:
	if _tileDefinitions.has(tile_type):
		return _tileDefinitions[tile_type]
	return _tileDefinitions[Type.NONE]
