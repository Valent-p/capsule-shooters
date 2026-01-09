# /levels/generation/corridor_generator.gd
# Connects rooms by carving corridors using A* pathfinding.
class_name CorridorGenerator
extends Object

const MAX_CONNECTION_ATTEMPTS = 3 # How many times to try connecting a room before giving up.

# Main function to generate corridors between all rooms.
static func generate_corridors(p_grid: Array, p_rooms: Array, p_level_size: Vector2i) -> Array:
	var corridors: Array[Vector2i]
	if p_rooms.size() < 2:
		return corridors

	# --- 1. Build A* grid ---
	var astar = AStar2D.new()
	_setup_astar_grid(astar, p_grid, p_rooms, p_level_size)

	# --- 2. Connect Rooms ---
	# This uses a simple sequential connection. For more organic layouts,
	# a Minimum Spanning Tree (MST) approach on a graph of rooms would be an excellent upgrade.
	for i in range(1, p_rooms.size()):
		var room_a = p_rooms[i-1]
		var room_b = p_rooms[i]
		
		var success = _try_connect_rooms(room_a, room_b, astar, p_grid, corridors, p_level_size)
		
		# SUGGESTION IMPLEMENTED: Handle disconnected rooms.
		# If direct connection fails, try connecting room_b to ANY other already-connected room.
		if not success:
			var attempts = 0
			while not success and attempts < MAX_CONNECTION_ATTEMPTS:
				attempts += 1
				# Pick a random room that is part of the connected graph (i.e., any room before i).
				var random_connected_room = p_rooms[randi() % i]
				success = _try_connect_rooms(random_connected_room, room_b, astar, p_grid, corridors, p_level_size)

		if not success:
			print("WARNING: Could not connect Room ", room_b.id, " to the rest of the level.")


	return corridors


# Sets up the A* points and their weights based on the level grid.
static func _setup_astar_grid(p_astar: AStar2D, p_grid: Array, p_rooms: Array, p_level_size: Vector2i):
	# Add all points to A*
	for x in range(p_level_size.x):
		for y in range(p_level_size.y):
			var idx = y * p_level_size.x + x
			var tile: LevelTileData = p_grid[x][y]
			var weight = 1.0 # Default weight for empty space.

			if tile.is_room:
				if tile.is_prefab:
					# In prefabs, only allow pathfinding through designated entrances.
					var is_entrance = false
					if tile.room_id != -1: # Should always be true for a room tile
						var room = p_rooms[tile.room_id]
						if Vector2i(x, y) in room.global_entrances:
							is_entrance = true
					
					if is_entrance:
						weight = 1.0
					else:
						# If it's part of a prefab but not an entrance, disable it for A*.
						p_astar.add_point(idx, Vector2(x,y), 0) # Weight is irrelevant.
						p_astar.set_point_disabled(idx, true)
						continue
				else:
					# Standard procedural rooms are traversable but expensive.
					# This encourages corridors to be carved outside of rooms when possible.
					weight = 5.0
			
			p_astar.add_point(idx, Vector2(x, y), weight)

	# Connect all adjacent, non-disabled points.
	for x in range(p_level_size.x):
		for y in range(p_level_size.y):
			var idx1 = y * p_level_size.x + x
			# Only need to check right and down, as connections are bidirectional.
			for dir in [Vector2i(1, 0), Vector2i(0, 1)]:
				var nx = x + dir.x
				var ny = y + dir.y
				if nx < p_level_size.x and ny < p_level_size.y:
					var idx2 = ny * p_level_size.x + nx
					if not p_astar.is_point_disabled(idx1) and not p_astar.is_point_disabled(idx2):
						p_astar.connect_points(idx1, idx2, true)


# Tries to find and carve a path between two rooms.
static func _try_connect_rooms(p_room_a: Room, p_room_b: Room, p_astar: AStar2D, p_grid: Array, r_corridors: Array, p_level_size: Vector2i) -> bool:
	var start_pos = p_room_a.get_connection_point(p_room_b.rect.get_center())
	var end_pos = p_room_b.get_connection_point(p_room_a.rect.get_center())
	
	var start_idx = start_pos.y * p_level_size.x + start_pos.x
	var end_idx = end_pos.y * p_level_size.x + end_pos.x
	
	var path_points = p_astar.get_point_path(start_idx, end_idx)
	
	if path_points.is_empty():
		return false

	# Carve the path into the grid.
	for point_pos in path_points:
		var px = int(point_pos.x)
		var py = int(point_pos.y)
		var tile_data: LevelTileData = p_grid[px][py]
		if not tile_data.is_floor:
			tile_data.is_floor = true
			tile_data.is_corridor = true
		if not Vector2i(px, py) in r_corridors:
			r_corridors.append(Vector2i(px, py))
			
	return true
