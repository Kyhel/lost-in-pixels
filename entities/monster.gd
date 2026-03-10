extends CharacterBody2D

const TILE_SIZE = 16
const SPEED = 40
const TURN_SPEED = 6.0

enum State {
	IDLE,
	TURNING,
	MOVING
}

var state = State.IDLE

var target_direction = Vector2.ZERO
var target_rotation = 0.0
var move_target = Vector2.ZERO
var idle_timer = 0.0
var chunk_coord : Vector2i
var stuck_time := 0.0
var last_position := Vector2.ZERO
var health := 3

func _ready():
	randomize()
	pick_new_direction()
	chunk_coord = ChunkManager.get_chunk_from_position(global_position)
	last_position = global_position

func _physics_process(delta):

	match state:

		State.TURNING:
			rotation = rotate_toward(rotation, target_rotation, TURN_SPEED * delta)

			if abs(angle_difference(rotation, target_rotation)) < 0.05:
				state = State.MOVING

		State.MOVING:
			var dir = target_direction
			# Check the terrain ahead; if it's not walkable (e.g. water), stop and idle
			var tile_def = ChunkManager.get_tile_def_from_world_pos(global_position + dir * TILE_SIZE * 0.5)
			if tile_def.has("walkable") and tile_def["walkable"] == false:
				go_idle()
				return

			var before_move_pos := global_position
			velocity = dir * SPEED
			move_and_slide()

			var moved_dist := global_position.distance_to(before_move_pos)
			if moved_dist < 0.5:
				stuck_time += delta
				if stuck_time > 0.5:
					go_idle()
					return
			else:
				stuck_time = 0.0

						# 🔹 Vérifier si le monstre a changé de chunk
			var old_chunk = chunk_coord
			var new_chunk = ChunkManager.get_chunk_from_position(global_position)

			if new_chunk != old_chunk:
				EntitiesManager.move_monster(self, old_chunk, new_chunk)
				chunk_coord = new_chunk

			if global_position.distance_to(move_target) < 2:
				go_idle()

		State.IDLE:
			idle_timer -= delta

			if idle_timer <= 0:
				pick_new_direction()


func pick_new_direction():

	var dirs = [
		Vector2.UP,
		Vector2.DOWN,
		Vector2.LEFT,
		Vector2.RIGHT
	]

	target_direction = dirs.pick_random()

	target_rotation = target_direction.angle()

	move_target = global_position + target_direction * TILE_SIZE

	state = State.TURNING


func go_idle():
	velocity = Vector2.ZERO
	stuck_time = 0.0
	state = State.IDLE
	idle_timer = 1.0

func take_damage(amount):

	health -= amount

	if health <= 0:
		die()

func die():
	# Drop a simple item on death.
	var drop_item = ItemDatabase.get_item(&"coin")
	if drop_item:
		ObjectsManager.spawn_item_in_chunk(chunk_coord, drop_item, global_position)

	queue_free()
