extends Node
class_name TerrainGenerator

enum Biome {
	NONE,
	FOREST,
	PLAINS,
	DESERT,
	MOUNTAIN,
	LAVA,
	TOXIC,
	WATER,
	DEAD,
	SWAMP,
	TUNDRA,
}

var terrain_noise := FastNoiseLite.new()
var biome_noise := FastNoiseLite.new()

var noise_wavelength := 50.0

var world_scale: float = 30.0
var max_danger_radius: float = 10.0 * world_scale
var safe_radius_ratio: float = 0.2
var height_wavelength = 10.0 * world_scale
var temperature_wavelength = 20.0 * world_scale
var moisture_wavelength = 20.0 * world_scale
var large_scale_wavelength = 40.0 * world_scale
var danger_wavelength = 20.0 * world_scale
var water_level: float = -0.2
var beach_margin: float = 0.05
var mountain_level: float = 0.5
var danger_exponent: float = 2.0
var directional_noise_strength: float = 0.2
var warp_strength: float = 100.0
var smoothing_enabled: bool = true
var smoothing_passes: int = 2

var height_noise := FastNoiseLite.new()
var temperature_noise := FastNoiseLite.new()
var moisture_noise := FastNoiseLite.new()
var large_scale_noise := FastNoiseLite.new()
var danger_noise := FastNoiseLite.new()

func _init() -> void:
	terrain_noise.frequency = 1 / noise_wavelength
	biome_noise.frequency = terrain_noise.frequency / 3
	height_noise.frequency = 1.0 / height_wavelength
	temperature_noise.frequency = 1.0 / temperature_wavelength
	moisture_noise.frequency = 1.0 / moisture_wavelength
	large_scale_noise.frequency = 1.0 / large_scale_wavelength
	danger_noise.frequency = 1.0 / danger_wavelength


func setup_seed(p_seed: int) -> void:
	terrain_noise.seed = p_seed
	biome_noise.seed = p_seed + 1000
	height_noise.seed = p_seed
	temperature_noise.seed = p_seed + 1000
	moisture_noise.seed = p_seed + 2000
	large_scale_noise.seed = p_seed + 3000
	danger_noise.seed = p_seed + 5000


func get_tile_type(world_x: int, world_y: int) -> int:
	var wx := int(floor(world_x))
	var wy := int(floor(world_y))
	if not smoothing_enabled:
		return _get_tile_raw(float(wx), float(wy))
	var passes: int = clampi(smoothing_passes, 1, 2)
	var tile: int = _tile_majority_3x3(Callable(self, "_sample_raw_tile"), wx, wy)
	if passes >= 2:
		tile = _tile_majority_3x3(Callable(self, "_get_tile_pass1"), wx, wy)
	return tile


## Use this when you already have a tile type (e.g. from Chunk tile data) instead of calling get_biome / get_tile_type again.
func biome_from_tile_type(tile_type: int) -> Biome:
	match tile_type:
		Terrain.Type.NONE:
			return Biome.NONE
		Terrain.Type.WATER:
			return Biome.WATER
		Terrain.Type.BEACH:
			return Biome.WATER
		Terrain.Type.GRASS:
			return Biome.PLAINS
		Terrain.Type.DARK_GRASS:
			return Biome.FOREST
		Terrain.Type.SAND:
			return Biome.DESERT
		Terrain.Type.SNOW:
			return Biome.MOUNTAIN
		Terrain.Type.LAVA:
			return Biome.LAVA
		Terrain.Type.TOXIC:
			return Biome.TOXIC
		Terrain.Type.DEAD:
			return Biome.DEAD
		Terrain.Type.SWAMP:
			return Biome.SWAMP
		Terrain.Type.TUNDRA:
			return Biome.TUNDRA
		_:
			return Biome.PLAINS


func get_biome(world_x: int, world_y: int) -> Biome:
	return biome_from_tile_type(get_tile_type(world_x, world_y))


func _sample_raw_tile(tx: int, ty: int) -> int:
	return _get_tile_raw(float(tx), float(ty))


func _get_tile_pass1(tx: int, ty: int) -> int:
	return _tile_majority_3x3(Callable(self, "_sample_raw_tile"), tx, ty)


func _tile_majority_3x3(sample: Callable, wx: int, wy: int) -> int:
	var center: int = sample.call(wx, wy)
	var counts: Dictionary = {}
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var tile: int = sample.call(wx + dx, wy + dy)
			counts[tile] = int(counts.get(tile, 0)) + 1
	return _resolve_majority_tie(center, counts)


func _resolve_majority_tie(center: int, counts: Dictionary) -> int:
	var best_count := -1
	for c in counts.values():
		if c > best_count:
			best_count = c
	var winners: Array[int] = []
	for k in counts.keys():
		if counts[k] == best_count:
			winners.append(k)
	if winners.size() == 1:
		return winners[0]
	for winner in winners:
		if winner == center:
			return center
	winners.sort_custom(func(a: int, b: int) -> bool:
		return int(a) < int(b))
	return winners[0]


func _majority_flat9(raw: PackedInt32Array, pw: int, px: int, py: int) -> int:
	var counts: Dictionary = {}
	for j in range(3):
		for i in range(3):
			var tile: int = raw[(py + j) * pw + (px + i)]
			counts[tile] = int(counts.get(tile, 0)) + 1
	var center: int = raw[(py + 1) * pw + (px + 1)]
	return _resolve_majority_tie(center, counts)


func compute_chunk_tile_types(chunk_x: int, chunk_y: int, chunk_size: int) -> Array[int]:
	var out: Array[int] = []
	out.resize(chunk_size * chunk_size)
	if not smoothing_enabled:
		var index := 0
		for x in range(chunk_size):
			for y in range(chunk_size):
				out[index] = _get_tile_raw(float(chunk_x * chunk_size + x), float(chunk_y * chunk_size + y))
				index += 1
		return out
	var passes: int = clampi(smoothing_passes, 1, 2)
	if passes == 1:
		var pw: int = chunk_size + 2
		var raw: PackedInt32Array = PackedInt32Array()
		raw.resize(pw * pw)
		for py in range(pw):
			for px in range(pw):
				var wx: int = chunk_x * chunk_size + px - 1
				var wy: int = chunk_y * chunk_size + py - 1
				raw[py * pw + px] = int(_get_tile_raw(float(wx), float(wy)))
		var out_index := 0
		for x in range(chunk_size):
			for y in range(chunk_size):
				out[out_index] = _majority_flat9(raw, pw, x, y)
				out_index += 1
		return out
	var pw2: int = chunk_size + 4
	var raw2: PackedInt32Array = PackedInt32Array()
	raw2.resize(pw2 * pw2)
	for py in range(pw2):
		for px in range(pw2):
			var wx2: int = chunk_x * chunk_size + px - 2
			var wy2: int = chunk_y * chunk_size + py - 2
			raw2[py * pw2 + px] = int(_get_tile_raw(float(wx2), float(wy2)))
	var p1w: int = chunk_size + 2
	var pass1: PackedInt32Array = PackedInt32Array()
	pass1.resize(p1w * p1w)
	for j in range(p1w):
		for i in range(p1w):
			pass1[j * p1w + i] = int(_majority_flat9(raw2, pw2, i, j))
	var out_index_2 := 0
	for x in range(chunk_size):
		for y in range(chunk_size):
			out[out_index_2] = _majority_flat9(pass1, p1w, x, y)
			out_index_2 += 1
	return out


func _get_tile_raw(x: float, y: float) -> int:
	var height = get_height(x, y)
	if height < water_level:
		return Terrain.Type.WATER
	if height < water_level + beach_margin:
		return Terrain.Type.BEACH
	var safe_factor = get_safe_factor(x, y)
	var danger = get_danger(x, y, safe_factor)
	var climate = get_climate(x, y)
	var temperature = climate.x
	var moisture = climate.y
	if danger > 0.5:
		return pick_tiletype(compute_danger_biome_weights(temperature, moisture))
	return pick_tiletype(compute_safe_biome_weights(temperature, moisture))


func get_height(x: float, y: float) -> float:
	return height_noise.get_noise_2d(x, y)


func get_safe_factor(x: float, y: float) -> float:
	var dist = Vector2(x, y).length() / max_danger_radius
	dist = clamp(dist, 0.0, 1.0)
	if dist < safe_radius_ratio:
		return 0.0
	return (dist - safe_radius_ratio) / (1.0 - safe_radius_ratio)


func get_danger(x: float, y: float, safe_factor: float) -> float:
	var danger = pow(safe_factor, danger_exponent)
	var dir_noise = danger_noise.get_noise_2d(x, y)
	danger *= (dir_noise + 1) * 0.5
	danger += dir_noise * directional_noise_strength
	return clamp(danger, 0.0, 1.0)


func compute_safe_biome_weights(temp: float, moist: float) -> Dictionary:
	var weights = {}
	weights[Terrain.Type.DARK_GRASS] = 1.5 * moist * temp
	weights[Terrain.Type.SAND] = (1.0 - moist) * temp
	weights[Terrain.Type.GRASS] = 0.5 * (1.0 - abs(moist - 0.5)) * (1.0 - abs(temp - 0.5))
	return normalize_weights(weights)


func compute_danger_biome_weights(temp: float, _moist: float) -> Dictionary:
	var weights = {}
	weights[Terrain.Type.TOXIC] = (1.0 - temp)
	weights[Terrain.Type.LAVA] = temp
	weights[Terrain.Type.GRASS] = 0.7 * (1.0 - abs(temp - 0.5))
	return normalize_weights(weights)


func pick_tiletype(weights: Dictionary) -> int:
	var best_key = Terrain.Type.NONE
	var best_val = -INF
	for key in weights.keys():
		var value = weights[key]
		if value > best_val:
			best_val = value
			best_key = key
	return best_key


func get_climate(x: float, y: float) -> Vector2:
	var warp = large_scale_noise.get_noise_2d(x * 0.05, y * 0.05)
	var warped_x = x + warp * warp_strength
	var warped_y = y + warp * warp_strength
	var temp = temperature_noise.get_noise_2d(warped_x, warped_y)
	var moist = moisture_noise.get_noise_2d(warped_x, warped_y)
	temp = (temp + 1.0) * 0.5
	moist = (moist + 1.0) * 0.5
	return Vector2(temp, moist)


func normalize_weights(weights: Dictionary) -> Dictionary:
	var total = 0.0
	for value in weights.values():
		total += value
	if total == 0:
		return weights
	for key in weights.keys():
		weights[key] /= total
	return weights
