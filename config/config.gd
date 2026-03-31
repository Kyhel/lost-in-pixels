class_name Config
extends Resource

@export var spawn_rabbits := true
@export var allowed_creatures : Array[CreatureData] = []
@export var biome_creature_spawn_profiles : Array[Resource] = []
@export var chunk_load_radius := 4
@export var max_creatures_per_chunk := 5
@export var spawn_trees := true
@export var spawn_small_vegetation := true
@export var small_vegetation: Array[ObjectData] = []
@export var spawn_world_objects := true
@export var player_light := true
@export var camera_zoom_level := 1.5
@export var starting_abilities: Array[AbilityData] = []
