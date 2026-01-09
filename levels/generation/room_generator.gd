# /levels/generation/room_generator.gd
# Responsible for creating and placing rooms and prefabs on the grid.
class_name RoomGenerator
extends Object

# Main function to generate all rooms.
# It places unique prefabs first, then fills the rest with random prefabs and procedural rooms.
static func generate_rooms(p_grid: Array, p_params: Dictionary) -> Array:
	var rooms: Array[Room]
	var current_room_id = 0
	
	# Create a copy of prefab definitions to avoid modifying the original resource.
	var available_prefabs = p_params.prefab_defs.duplicate()
	
	# --- 1. Place all UNIQUE prefabs ---
	# These must be placed, so we try until they fit.
	for prefab_data in p_params.prefab_defs:
		if prefab_data.unique:
			# This is a bit risky. If a unique prefab is too large, this could be an infinite loop.
			# A max_attempts check on placing unique prefabs might be needed for safety.
			var placed = false
			while not placed:
				placed = _try_place_prefab(prefab_data, current_room_id, p_grid, rooms, p_params)
			current_room_id += 1
			# Remove from available list so it's not placed again.
			available_prefabs.erase(prefab_data)

	# --- 2. Place remaining rooms and prefabs ---
	var attempts = 0
	var max_attempts = p_params.room_count * 10
	while rooms.size() < p_params.room_count and attempts < max_attempts:
		attempts += 1
		var placed = false
		# Decide whether to place a prefab or a procedural room.
		if p_params.rng.randf() < p_params.prefab_chance and not available_prefabs.is_empty():
			# Try to place a random, non-unique prefab.
			var prefab_data = available_prefabs.pick_random()
			placed = _try_place_prefab(prefab_data, current_room_id, p_grid, rooms, p_params)
			if placed and prefab_data.unique: # Should not happen if logic is correct, but for safety.
				available_prefabs.erase(prefab_data)
		else:
			# Place a procedural room.
			placed = _try_place_procedural_room(current_room_id, p_grid, rooms, p_params)
		
		if placed:
			current_room_id += 1
			
	return rooms


# Attempts to place a single procedural room. Returns true on success.
static func _try_place_procedural_room(p_id: int, p_grid: Array, p_rooms: Array, p_params: Dictionary) -> bool:
	var w = p_params.rng.randi_range(p_params.min_room_size.x, p_params.max_room_size.x)
	var h = p_params.rng.randi_range(p_params.min_room_size.y, p_params.max_room_size.y)
	
	# Buffer to avoid edge-of-map issues.
	var x = p_params.rng.randi_range(1, p_params.level_size.x - w - 2)
	var y = p_params.rng.randi_range(1, p_params.level_size.y - h - 2)
	
	var new_rect = Rect2i(x, y, w, h)
	
	# Check for overlaps with existing rooms.
	for room in p_rooms:
		if room.rect.grow(1).intersects(new_rect):
			return false # Overlap found, placement failed.
			
	# --- Placement successful ---
	var new_room = Room.new(p_id, new_rect)
	new_room.density_modifier = p_params.rng.randf_range(0.5, 1.5)
	p_rooms.append(new_room)
	
	# Mark the grid with the new room's tiles.
	_carve_room_into_grid(new_room, p_grid)
	
	return true


# Attempts to place a single prefab. Returns true on success.
static func _try_place_prefab(p_prefab_data: PrefabItemData, p_id: int, p_grid: Array, p_rooms: Array, p_params: Dictionary) -> bool:
	var w: int
	var h: int
	
	# --- 1. Decide Rotation and Dimensions ---
	var chosen_dir = p_prefab_data.fixed_direction
	if p_prefab_data.randomize_rotation:
		chosen_dir = p_params.rng.randi_range(0, 3)
		
	# Swap width/height based on rotation.
	if chosen_dir == PrefabItemData.Direction.EAST or chosen_dir == PrefabItemData.Direction.WEST:
		w = p_prefab_data.height
		h = p_prefab_data.width
	else:
		w = p_prefab_data.width
		h = p_prefab_data.height
		
	# --- 2. Find Spot and Check Overlaps ---
	var x = p_params.rng.randi_range(1, p_params.level_size.x - w - 2)
	var y = p_params.rng.randi_range(1, p_params.level_size.y - h - 2)
	var new_rect = Rect2i(x, y, w, h)
	
	for room in p_rooms:
		if room.rect.grow(1).intersects(new_rect):
			return false # Overlap.

	# --- 3. Validate Entrances ---
	# Create a temporary room object to calculate global entrance positions.
	var temp_room = Room.new(p_id, new_rect, p_prefab_data.prefab_scene, chosen_dir)
	_calculate_global_entrances(temp_room, p_prefab_data)
	
	# Check if entrances are valid (not facing map edge or blocked).
	if not _are_entrances_valid(temp_room, p_grid, p_params.level_size):
		return false
		
	# --- 4. Placement Successful ---
	p_rooms.append(temp_room)
	_carve_room_into_grid(temp_room, p_grid)
	
	return true


# Calculates the real-world grid positions of a prefab's entrances based on its rotation.
static func _calculate_global_entrances(p_room: Room, p_prefab_data: PrefabItemData):
	p_room.global_entrances.clear()
	for entrance_local in p_prefab_data.entrances:
		# Pass ORIGINAL width/height to rotation helper.
		var rotated_entrance = _rotate_point(entrance_local, p_room.rotation_dir, p_prefab_data.width, p_prefab_data.height)
		var global_pos = p_room.rect.position + rotated_entrance
		p_room.global_entrances.append(global_pos)


# Rotates a point within a prefab's local coordinate space.
static func _rotate_point(p_point: Vector2i, p_dir: int, p_original_w: int, p_original_h: int) -> Vector2i:
	match p_dir:
		PrefabItemData.Direction.NORTH: return p_point
		PrefabItemData.Direction.EAST:  return Vector2i(p_original_h - 1 - p_point.y, p_point.x)
		PrefabItemData.Direction.SOUTH: return Vector2i(p_original_w - 1 - p_point.x, p_original_h - 1 - p_point.y)
		PrefabItemData.Direction.WEST:  return Vector2i(p_point.y, p_original_w - 1 - p_point.x)
	return p_point # Should not happen


# Checks if prefab entrances are blocked by other rooms or face the edge of the map.
static func _are_entrances_valid(p_room: Room, p_grid: Array, p_level_size: Vector2i) -> bool:
	if p_room.global_entrances.is_empty():
		return true # No entrances, no problem.

	for door_pos in p_room.global_entrances:
		var has_at_least_one_exit = false
		# Check all 4 directions from the door tile.
		for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var check_pos = door_pos + dir
			# Ensure the check position is within the map bounds.
			if check_pos.x >= 0 and check_pos.x < p_level_size.x and check_pos.y >= 0 and check_pos.y < p_level_size.y:
				# If we find a non-room tile, it means there's a potential path out.
				if not p_grid[check_pos.x][check_pos.y].is_room:
					has_at_least_one_exit = true
					break # Found an exit for this door.
		
		# If a door has no possible exit paths, the placement is invalid.
		if not has_at_least_one_exit:
			return false
			
	return true


# Marks the grid tiles occupied by a room.
static func _carve_room_into_grid(p_room: Room, p_grid: Array):
	for i in range(p_room.rect.size.x):
		for j in range(p_room.rect.size.y):
			var tile_data: LevelTileData = p_grid[p_room.rect.position.x + i][p_room.rect.position.y + j]
			tile_data.is_floor = true
			tile_data.is_room = true
			tile_data.room_id = p_room.id
			if p_room.prefab_scene != null:
				tile_data.is_prefab = true
