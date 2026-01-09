extends Node

@export var enemy_scene: PackedScene

# This utility function is the key to solving your problem.
func grid_to_world_position(grid_pos: Vector2i, y_offset: float = 1.0) -> Vector3:
	# Converts a 2D grid coordinate to a 3D world position.
	# The y_offset places the enemy slightly above the floor.
	return Vector3(grid_pos.x * 4.0 + 2.0, y_offset, grid_pos.y * 4.0 + 2.0)

func spawn_enemies(level_data: Dictionary):
	spawn_enemy_in_random_room(level_data.rooms, enemy_scene)

func spawn_enemy_in_random_room(p_rooms: Array, p_enemy_scene: PackedScene):
	if p_rooms.is_empty():
		return

	# 1. Pick a random room from the generated level data.
	var random_room: Room = p_rooms.pick_random()

	# 2. Get a random tile coordinate from within that room's rectangle.
	var spawn_grid_pos = Vector2i(
		randi_range(random_room.rect.position.x, random_room.rect.end.x - 1),
		randi_range(random_room.rect.position.y, random_room.rect.end.y - 1)
	)

	# 3. Convert that grid coordinate to a 3D world position using the utility function.
	var spawn_world_pos = grid_to_world_position(spawn_grid_pos)

	# 4. Instantiate and place the enemy.
	var enemy = p_enemy_scene.instantiate()
	enemy.position = spawn_world_pos
	add_child(enemy) # Or add to a specific "Enemies" node
	
	print("Spawned enemy at grid ", spawn_grid_pos, " (world: ", spawn_world_pos, ")")
