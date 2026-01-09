# /levels/generation/tile_analyzer.gd
# Analyzes the generated grid to determine detailed tile characteristics.
class_name TileAnalyzer
extends Object

# Main analysis function. It iterates through the grid and calculates properties
# for each tile based on its neighbors.
static func analyze_tiles(p_grid: Array, p_rooms: Array, p_corridors: Array, p_level_size: Vector2i):
	# --- Pass 1: Basic Wall and Floor Analysis ---
	# Determines wall status, neighbor counts, and corner/edge properties.
	for x in range(p_level_size.x):
		for y in range(p_level_size.y):
			var tile: LevelTileData = p_grid[x][y]
			
			# If a tile is not a floor, check if it should become a wall.
			if not tile.is_floor:
				for i in range(-1, 2):
					for j in range(-1, 2):
						if i == 0 and j == 0: continue
						var nx = x + i
						var ny = y + j
						if _is_in_bounds(nx, ny, p_level_size) and p_grid[nx][ny].is_floor:
							tile.is_wall = true
							break
					if tile.is_wall: break
				continue # Move to next tile.

			# --- If it IS a floor tile, analyze its neighbors ---
			var neighbor_count = 0      # 8 directions
			var cardinal_neighbor_count = 0 # 4 directions
			
			# 8-direction check for "surrounded" status.
			for i in range(-1, 2):
				for j in range(-1, 2):
					if i == 0 and j == 0: continue
					var nx = x + i
					var ny = y + j
					if _is_in_bounds(nx, ny, p_level_size) and p_grid[nx][ny].is_floor:
						neighbor_count += 1
			
			tile.neighbor_count = neighbor_count
			if neighbor_count == 8:
				tile.is_surrounded = true

			# 4-direction check for wall adjacency, corners, and corridor intersections.
			var wall_count = 0
			for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var nx = x + dir.x
				var ny = y + dir.y
				if not _is_in_bounds(nx, ny, p_level_size) or not p_grid[nx][ny].is_floor:
					wall_count += 1
				else:
					cardinal_neighbor_count += 1
			
			tile.cardinal_neighbor_count = cardinal_neighbor_count
			if wall_count == 1: tile.is_wall_adjacent = true
			if wall_count >= 2: tile.is_corner = true # Simplified: a tile is a "corner" if it touches 2 or more walls.

	# --- Pass 2: Refine Corridor and Doorway Definitions ---
	# SUGGESTION IMPLEMENTED: Use cardinal neighbors for corridor analysis.
	var corridors_to_remove = []
	for corridor_pos in p_corridors:
		var x = corridor_pos.x
		var y = corridor_pos.y
		var tile: LevelTileData = p_grid[x][y]
		
		# If a corridor tile has more than 2 cardinal neighbors, it's an intersection (T-junction, cross).
		# We'll re-classify it as a "room" tile to allow more flexible POI/item placement.
		if tile.cardinal_neighbor_count > 2:
			tile.is_room = true
			tile.is_corridor = false
			tile.is_doorway = true # Mark it as a special "doorway" intersection.
			corridors_to_remove.append(corridor_pos)
			
			# Assign it to the nearest room for logical grouping.
			if tile.room_id == -1:
				_assign_tile_to_nearest_room(tile, x, y, p_rooms)
	
	# Clean up the main corridor list.
	for pos in corridors_to_remove:
		p_corridors.erase(pos)

# Helper to check if a grid coordinate is within the level bounds.
static func _is_in_bounds(x: int, y: int, p_level_size: Vector2i) -> bool:
	return x >= 0 and x < p_level_size.x and y >= 0 and y < p_level_size.y

# Finds the closest room to a given tile and assigns the room's ID to it.
static func _assign_tile_to_nearest_room(r_tile: LevelTileData, x: int, y: int, p_rooms: Array):
	var closest_room_id = -1
	var closest_dist = INF
	for room in p_rooms:
		var room_center = room.rect.get_center()
		var dist = Vector2(x, y).distance_squared_to(room_center)
		if dist < closest_dist:
			closest_dist = dist
			closest_room_id = room.id
	r_tile.room_id = closest_room_id
