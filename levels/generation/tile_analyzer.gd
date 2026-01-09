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

	# --- Pass 2: Refine and "Purify" Corridor Definitions ---
	# This pass ensures that only straight corridor segments are tagged as `is_corridor`.
	# L-bends, T-junctions, and crossings are reclassified as generic "room" or "doorway" tiles.
	var tiles_to_reclassify = []
	# We iterate over a copy because the main `p_corridors` array will be modified.
	for corridor_pos in p_corridors.duplicate():
		var x = corridor_pos.x
		var y = corridor_pos.y
		
		# Check for floor neighbors in all 4 cardinal directions.
		var up = y + 1 < p_level_size.y and p_grid[x][y+1].is_floor
		var down = y - 1 >= 0 and p_grid[x][y-1].is_floor
		var left = x - 1 >= 0 and p_grid[x-1][y].is_floor
		var right = x + 1 < p_level_size.x and p_grid[x+1][y].is_floor
		
		# A tile is a "pure" straight corridor piece if it has exactly two neighbors,
		# and those neighbors are opposite each other.
		var is_straight_horizontal = left and right and not up and not down
		var is_straight_vertical = up and down and not left and not right

		# If it's not a straight line piece, mark it for reclassification.
		if not (is_straight_horizontal or is_straight_vertical):
			tiles_to_reclassify.append(corridor_pos)

	# Now, reclassify all the identified non-straight corridor pieces.
	for pos in tiles_to_reclassify:
		var tile: LevelTileData = p_grid[pos.x][pos.y]
		tile.is_corridor = false
		tile.is_room = true # Reclassify as a generic "room" tile.
		
		# If it was an intersection, it's useful to mark it as a special doorway tile.
		if tile.cardinal_neighbor_count > 2:
			tile.is_doorway = true
		
		# Assign to the nearest room for logical grouping if it doesn't have an ID yet.
		if tile.room_id == -1:
			_assign_tile_to_nearest_room(tile, pos.x, pos.y, p_rooms)
		
		# Remove it from the main corridor list so placement functions won't see it.
		if p_corridors.has(pos):
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
