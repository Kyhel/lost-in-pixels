class_name WorldGenerator2
extends Node

# ============================================================
# 🌍 CONFIGURATION
# ============================================================

# World settings
var world_scale : float = 30.0
var max_danger_radius : float = 10.0 * world_scale
var safe_radius_ratio : float = 0.2  # 20% safe zone

# Noise settings
var height_wavelength = 5.0 * world_scale
var temperature_wavelength = 8.0 * world_scale
var moisture_wavelength = 8.0 * world_scale
var large_scale_wavelength = 20.0 * world_scale
var biome_wavelength = 30.0 * world_scale
var danger_wavelength = 20.0 * world_scale
# Terrain thresholds
var water_level : float = -0.2
var beach_margin : float = 0.05
var mountain_level : float = 0.5

# Danger tuning
var danger_exponent : float = 2.0
var directional_noise_strength : float = 0.2

# Domain warp
var warp_strength : float = 100.0

# Speckle removal: 3×3 majority over raw tiles (deterministic, chunk-boundary safe)
var smoothing_enabled: bool = true
## 1 = one majority pass; 2 = second pass over the first pass (stronger, ~9× more samples per tile)
var smoothing_passes: int = 2

# ============================================================
# 🌊 NOISE GENERATORS
# ============================================================

var height_noise := FastNoiseLite.new()
var temperature_noise := FastNoiseLite.new()
var moisture_noise := FastNoiseLite.new()
var large_scale_noise := FastNoiseLite.new()
var biome_noise := FastNoiseLite.new()
var danger_noise := FastNoiseLite.new()

# ============================================================
# 🚀 INITIALIZATION
# ============================================================

func _init():

	# Height noise
	height_noise.frequency = 1.0 / height_wavelength

	# Temperature noise
	temperature_noise.frequency = 1.0 / temperature_wavelength

	# Moisture noise
	moisture_noise.frequency = 1.0 / moisture_wavelength

	# Large scale noise (for warping & danger shaping)
	large_scale_noise.frequency = 1.0 / large_scale_wavelength

	# Biome noise
	biome_noise.frequency = 1.0 / biome_wavelength

	# Danger noise
	danger_noise.frequency = 1.0 / danger_wavelength

func setup_seed(p_seed: int):
	height_noise.seed = p_seed
	temperature_noise.seed = p_seed + 1000
	moisture_noise.seed = p_seed + 2000
	large_scale_noise.seed = p_seed + 3000
	biome_noise.seed = p_seed + 4000
	danger_noise.seed = p_seed + 5000
# ============================================================
# 🧭 MAIN ENTRY POINT
# ============================================================

func get_tile(x: float, y: float) -> WorldGenerator.TileType:
	var wx := int(floor(x))
	var wy := int(floor(y))
	if not smoothing_enabled:
		return _get_tile_raw(float(wx), float(wy))
	var passes: int = clampi(smoothing_passes, 1, 2)
	var t: WorldGenerator.TileType = _tile_majority_3x3(Callable(self, "_sample_raw_tile"), wx, wy)
	if passes >= 2:
		t = _tile_majority_3x3(Callable(self, "_get_tile_pass1"), wx, wy)
	return t


func _sample_raw_tile(tx: int, ty: int) -> WorldGenerator.TileType:
	return _get_tile_raw(float(tx), float(ty))


func _get_tile_pass1(tx: int, ty: int) -> WorldGenerator.TileType:
	return _tile_majority_3x3(Callable(self, "_sample_raw_tile"), tx, ty)


func _tile_majority_3x3(sample: Callable, wx: int, wy: int) -> WorldGenerator.TileType:
	var center: WorldGenerator.TileType = sample.call(wx, wy)
	var counts: Dictionary = {}
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var t: WorldGenerator.TileType = sample.call(wx + dx, wy + dy)
			counts[t] = int(counts.get(t, 0)) + 1
	return _resolve_majority_tie(center, counts)


func _resolve_majority_tie(center: WorldGenerator.TileType, counts: Dictionary) -> WorldGenerator.TileType:
	var best_count := -1
	for c in counts.values():
		if c > best_count:
			best_count = c
	var winners: Array[WorldGenerator.TileType] = []
	for k in counts.keys():
		if counts[k] == best_count:
			winners.append(k)
	if winners.size() == 1:
		return winners[0]
	for w in winners:
		if w == center:
			return center
	winners.sort_custom(func(a: WorldGenerator.TileType, b: WorldGenerator.TileType) -> bool:
		return int(a) < int(b))
	return winners[0]


func _majority_flat9(raw: PackedInt32Array, pw: int, px: int, py: int) -> WorldGenerator.TileType:
	var counts: Dictionary = {}
	for j in range(3):
		for i in range(3):
			var t: WorldGenerator.TileType = raw[(py + j) * pw + (px + i)] as WorldGenerator.TileType
			counts[t] = int(counts.get(t, 0)) + 1
	var center: WorldGenerator.TileType = raw[(py + 1) * pw + (px + 1)] as WorldGenerator.TileType
	return _resolve_majority_tie(center, counts)


## Smoothed tile types for one chunk; order matches Chunk flat index [x * chunk_size + y].
func compute_chunk_tile_types(chunk_x: int, chunk_y: int, chunk_size: int) -> Array[WorldGenerator.TileType]:
	var out: Array[WorldGenerator.TileType] = []
	out.resize(chunk_size * chunk_size)
	if not smoothing_enabled:
		var i := 0
		for x in range(chunk_size):
			for y in range(chunk_size):
				out[i] = _get_tile_raw(float(chunk_x * chunk_size + x), float(chunk_y * chunk_size + y))
				i += 1
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
		var o := 0
		for x in range(chunk_size):
			for y in range(chunk_size):
				out[o] = _majority_flat9(raw, pw, x, y)
				o += 1
		return out
	# Two passes: larger raw halo so pass1 exists on a (chunk_size+2) grid
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
	var o2 := 0
	for x in range(chunk_size):
		for y in range(chunk_size):
			out[o2] = _majority_flat9(pass1, p1w, x, y)
			o2 += 1
	return out


func _get_tile_raw(x: float, y: float) -> WorldGenerator.TileType:
	# 1. Height check (water / land separation)
	var height = get_height(x, y)

	if height < water_level:
		return WorldGenerator.TileType.WATER

	if height < water_level + beach_margin:
		return WorldGenerator.TileType.BEACH

	#if height > mountain_level:
		#return WorldGenerator.TileType.SNOW

	# 2. Distance & danger computation
	var safe_factor = get_safe_factor(x, y)
	var danger = get_danger(x, y, safe_factor)

	# danger *= safe_factor

	# if danger > 0.8:
	# 	return WorldGenerator.TileType.LAVA
	# if danger > 0.6:
	# 	return WorldGenerator.TileType.TOXIC
	# if danger > 0.4:
	# 	return WorldGenerator.TileType.DEAD
	# if danger > 0.2:
	# 	return WorldGenerator.TileType.SAND
	# if danger > 0:
	# 	return WorldGenerator.TileType.DARK_GRASS
	# return WorldGenerator.TileType.GRASS

	# 3. Climate sampling (with domain warping)
	var climate = get_climate(x, y)
	var temperature = climate.x
	var moisture = climate.y

	if danger > 0.5:
		return pick_tiletype(compute_danger_biome_weights(temperature, moisture))
	else:
		return pick_tiletype(compute_safe_biome_weights(temperature, moisture))


func get_height(x: float, y: float) -> float:
	return height_noise.get_noise_2d(x, y)


# ============================================================
# 📏 DISTANCE & SAFE ZONE
# ============================================================

func get_safe_factor(x: float, y: float) -> float:

	var dist = Vector2(x, y).length() / max_danger_radius
	dist = clamp(dist, 0.0, 1.0)

	if dist < safe_radius_ratio:
		return 0.0

	return (dist - safe_radius_ratio) / (1.0 - safe_radius_ratio)


# ============================================================
# ☠️ DANGER SYSTEM
# ============================================================

func get_danger(x: float, y: float, safe_factor: float) -> float:
	# Base radial danger
	var danger = pow(safe_factor, danger_exponent)

	# Add directional / large-scale variation
	var dir_noise = danger_noise.get_noise_2d(x, y)

	danger *= (dir_noise + 1) * 0.5
	danger += dir_noise * directional_noise_strength

	return clamp(danger, 0.0, 1.0)


# ============================================================
# 🌿 BIOME WEIGHTS
# ============================================================

func compute_safe_biome_weights(temp: float, moist: float) -> Dictionary:
	var weights = {}

	# 5 biome categories
	# weights[WorldGenerator.TileType.SWAMP] = 1.1 * moist * (1.0 - temp)
	# weights[WorldGenerator.TileType.TUNDRA] = 0.7 * (1.0 - moist) * (1.0 - temp)
	weights[WorldGenerator.TileType.DARK_GRASS] = 1.5 * moist * temp
	weights[WorldGenerator.TileType.SAND] = (1.0 - moist) * temp
	weights[WorldGenerator.TileType.GRASS] = 0.5 * (1.0 - abs(moist - 0.5)) * (1.0 - abs(temp - 0.5))

	return normalize_weights(weights)

func compute_danger_biome_weights(temp: float, _moist: float) -> Dictionary:
	var weights = {}

	# 5 biome categories
	weights[WorldGenerator.TileType.TOXIC] = (1.0 - temp)
	weights[WorldGenerator.TileType.LAVA] = temp
	weights[WorldGenerator.TileType.GRASS] = 0.7 * (1.0 - abs(temp - 0.5))

	return normalize_weights(weights)


func pick_tiletype(weights: Dictionary) -> WorldGenerator.TileType:

	# First chose wining biome category
	var best_key = ""
	var best_val = -INF

	for k in weights.keys():
		var value = weights[k]
		if value > best_val:
			best_val = value
			best_key = k

	return best_key

# ============================================================
# 🌡 CLIMATE (TEMP + MOISTURE) WITH DOMAIN WARP
# ============================================================

func get_climate(x: float, y: float) -> Vector2:

	# Domain warp to break repetitive patterns
	var warp = large_scale_noise.get_noise_2d(x * 0.05, y * 0.05)

	var warped_x = x + warp * warp_strength
	var warped_y = y + warp * warp_strength

	var temp = temperature_noise.get_noise_2d(warped_x, warped_y)
	var moist = moisture_noise.get_noise_2d(warped_x, warped_y)

	# Normalize from [-1,1] → [0,1]
	temp = (temp + 1.0) * 0.5
	moist = (moist + 1.0) * 0.5

	return Vector2(temp, moist)


func normalize_weights(weights: Dictionary) -> Dictionary:
	var total = 0.0

	for v in weights.values():
		total += v

	if total == 0:
		return weights

	for k in weights.keys():
		weights[k] /= total

	return weights
