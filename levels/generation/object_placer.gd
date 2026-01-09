# /levels/generation/object_placer.gd
# Places all the 3D objects (floors, walls, POIs, items) into the scene.
class_name ObjectPlacer
extends Object

# Main placement function, called by the generator.
# Note: Node references (like `p_parent`) and scenes can't be static, so this is an instance method.
func place_all_objects(p_parent: Node3D, p_params: Dictionary):
	# The order of placement is important!
	_place_prefabs(p_parent, p_params.rooms)
	_place_floors(p_parent, p_params)
	
	# Place POIs before walls so they can correctly create openings in walls.
	var occupied_wall_edges = _place_pois(p_parent, p_params)
	
	_place_walls(p_parent, p_params, occupied_wall_edges)
	_place_items(p_parent, p_params)
	_place_dark_cubes(p_parent, p_params)


# --- INDIVIDUAL PLACEMENT FUNCTIONS ---

func _place_prefabs(p_parent: Node3D, p_rooms: Array):
	for room in p_rooms:
		if room.prefab_scene:
			var prefab_instance = room.prefab_scene.instantiate()
			# Position is top-left corner + center offset.
			var pos = Vector3(room.rect.position.x * 4, 0, room.rect.position.y * 4)
			var offset = Vector3(room.rect.size.x * 2.0, 0, room.rect.size.y * 2.0)
			prefab_instance.position = pos + offset
			prefab_instance.rotation_degrees.y = room.rotation_dir * -90
			p_parent.add_child(prefab_instance)

func _place_floors(p_parent: Node3D, p_params: Dictionary):
	for x in range(p_params.level_size.x):
		for y in range(p_params.level_size.y):
			var tile: LevelTileData = p_params.grid[x][y]
			# Place a floor tile if it's a floor and not part of an already-placed prefab.
			if tile.is_floor and not tile.is_prefab:
				var floor_tile = p_params.floor_scene.instantiate()
				floor_tile.position = Vector3(x * 4 + 2, 0, y * 4 + 2)
				p_parent.add_child(floor_tile)

func _place_pois(p_parent: Node3D, p_params: Dictionary) -> Dictionary:
	var occupied_wall_edges: Dictionary = {}
	for poi_def in p_params.poi_defs:
		if poi_def.poi_scene == null: continue

		for x in range(p_params.level_size.x):
			for y in range(p_params.level_size.y):
				var tile: LevelTileData = p_params.grid[x][y]

				if tile.is_prefab or tile.is_doorway: continue
				
				# BUG FIX: Use a dedicated function for POI placement check.
				var can_place = _can_place_poi(poi_def, tile)
				if not can_place: continue
				
				if p_params.rng.randf() >= poi_def.density: continue

				var poi = poi_def.poi_scene.instantiate()
				p_parent.add_child(poi)
				poi.position = Vector3(x * 4 + 2, poi_def.offset_y, y * 4 + 2)
				
				_align_poi(poi, x, y, poi_def, p_params, occupied_wall_edges)
				
	return occupied_wall_edges

func _place_walls(p_parent: Node3D, p_params: Dictionary, p_occupied_wall_edges: Dictionary):
	for x in range(p_params.level_size.x):
		for y in range(p_params.level_size.y):
			var tile: LevelTileData = p_params.grid[x][y]
			if tile.is_floor and not tile.is_prefab:
				for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
					var nx = x + dir.x
					var ny = y + dir.y
					if not TileAnalyzer._is_in_bounds(nx, ny, p_params.level_size) or not p_params.grid[nx][ny].is_floor:
						var wall_x = (x * 4) + 2 + (dir.x * 2)
						var wall_z = (y * 4) + 2 + (dir.y * 2)
						var key = Vector3i(wall_x, 0, wall_z)
						
						if p_occupied_wall_edges.has(key): continue
						
						var wall = p_params.wall_scene.instantiate()
						wall.position = Vector3(wall_x, 0, wall_z)
						if dir.x != 0: wall.rotation.y = deg_to_rad(90)
						p_parent.add_child(wall)

func _place_items(p_parent: Node3D, p_params: Dictionary):
	for item_def in p_params.item_defs:
		if item_def.use_scene == null: continue

		for x in range(p_params.level_size.x):
			for y in range(p_params.level_size.y):
				var tile: LevelTileData = p_params.grid[x][y]
				
				if tile.is_prefab or tile.is_doorway or not tile.is_floor: continue

				# BUG FIX: Use a dedicated, correct function for Item placement check.
				var can_place = _can_place_item(item_def, tile)
				if not can_place: continue
				
				if p_params.rng.randf() < item_def.density:
					var item = item_def.use_scene.instantiate()
					item.position = Vector3(x * 4 + 2, item_def.y_offset, y * 4 + 2)
					
					if item_def.rotation_type == PlaceableItemData.RotationType.RANDOM:
						item.rotation.y = p_params.rng.randf() * TAU
					elif item_def.rotation_type == PlaceableItemData.RotationType.GRID_SNAP:
						item.rotation_degrees.y = p_params.rng.randi_range(0, 3) * 90.0
					
					p_parent.add_child(item)

func _place_dark_cubes(p_parent: Node3D, p_params: Dictionary):
	for x in range(p_params.level_size.x):
		for y in range(p_params.level_size.y):
			var tile: LevelTileData = p_params.grid[x][y]
			if not tile.is_floor and not tile.is_prefab:
				var void_cube = p_params.void_cube_scene.instantiate()
				void_cube.position = Vector3(x*4+2, 2.05, y*4+2)
				p_parent.add_child(void_cube)

# --- HELPER FUNCTIONS ---

# Checks if a POI can be placed on a given tile.
func _can_place_poi(p_poi_def: POIData, p_tile: LevelTileData) -> bool:
	match p_poi_def.location_type:
		POIData.POILocationType.CORNER:
			return p_tile.is_corner and p_tile.is_room
		POIData.POILocationType.OPEN_SPACE:
			return p_tile.is_room and not p_tile.is_corner and not p_tile.is_wall_adjacent
		POIData.POILocationType.CORRIDOR_TILE:
			return p_tile.is_corridor
		POIData.POILocationType.WALL_BLOCK, POIData.POILocationType.WALL_FEATURE:
			return p_tile.is_wall_adjacent and p_tile.is_floor
	return false

# Checks if an Item can be placed on a given tile.
func _can_place_item(p_item_def: PlaceableItemData, p_tile: LevelTileData) -> bool:
	match p_item_def.location_type:
		PlaceableItemData.PlaceableLocationType.ROOM_TILE:
			if not p_tile.is_room: return false
			# Handle sub-location inside a room.
			match p_item_def.room_location:
				PlaceableItemData.RoomLocationType.OPEN_SPACE:
					return not p_tile.is_corner and not p_tile.is_wall_adjacent
				PlaceableItemData.RoomLocationType.CORNER:
					return p_tile.is_corner
				PlaceableItemData.RoomLocationType.WALL:
					return p_tile.is_wall_adjacent
		PlaceableItemData.PlaceableLocationType.CORRIDOR_TILE:
			return p_tile.is_corridor
		PlaceableItemData.PlaceableLocationType.WALL_TILE:
			# Assuming this means a floor tile adjacent to a wall.
			return p_tile.is_wall_adjacent and p_tile.is_floor
	return false


# Orients a POI after it has been placed.
func _align_poi(p_poi: Node3D, x: int, y: int, p_poi_def: POIData, p_params: Dictionary, r_occupied_wall_edges: Dictionary):
	var type = p_poi_def.location_type
	var direction = p_poi_def.direction
	
	if type == POIData.POILocationType.WALL_BLOCK:
		for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var nx = x + dir.x
			var ny = y + dir.y
			if not TileAnalyzer._is_in_bounds(nx, ny, p_params.level_size) or not p_params.grid[nx][ny].is_floor:
				var look_target = p_poi.position + Vector3(dir.x, 0, dir.y) 
				p_poi.look_at(look_target, Vector3.UP)
				var edge_pos = p_poi.position + Vector3(dir.x, 0, dir.y) * 2.0
				p_poi.position = edge_pos
				r_occupied_wall_edges[Vector3i(int(edge_pos.x), 0, int(edge_pos.z))] = true
				break
	elif direction == POIData.Direction.GRID_SNAP:
		if type == POIData.POILocationType.CORNER:
			var wall_dir_sum = Vector2i.ZERO
			for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var nx = x + dir.x
				var ny = y + dir.y
				if not TileAnalyzer._is_in_bounds(nx, ny, p_params.level_size) or not p_params.grid[nx][ny].is_floor:
					wall_dir_sum += dir
			if wall_dir_sum != Vector2i.ZERO:
				var look_target = p_poi.position - Vector3(wall_dir_sum.x, 0, wall_dir_sum.y)
				p_poi.look_at(look_target, Vector3.UP)

		elif type == POIData.POILocationType.WALL_FEATURE:
			for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var nx = x + dir.x
				var ny = y + dir.y
				if not TileAnalyzer._is_in_bounds(nx, ny, p_params.level_size) or not p_params.grid[nx][ny].is_floor:
					var look_target = p_poi.position - Vector3(dir.x, 0, dir.y) # Look AWAY from wall
					p_poi.look_at(look_target, Vector3.UP)
					break
		
		elif type == POIData.POILocationType.CORRIDOR_TILE:
			var left = x - 1 >= 0 and p_params.grid[x-1][y].is_floor
			var right = x + 1 < p_params.level_size.x and p_params.grid[x+1][y].is_floor
			var up = y + 1 < p_params.level_size.y and p_params.grid[x][y+1].is_floor
			var down = y - 1 >= 0 and p_params.grid[x][y-1].is_floor
			
			if (left and right) and not (up or down): # Horizontal corridor
				p_poi.rotation_degrees.y = p_params.rng.choice([90, -90])
			elif (up and down) and not (left or right): # Vertical corridor
				p_poi.rotation_degrees.y = p_params.rng.choice([0, 180])
				
	elif direction == POIData.Direction.RANDOM:
		p_poi.rotation.y = p_params.rng.randf() * TAU
	else: # NORTH, SOUTH, EAST, WEST
		p_poi.rotation_degrees.y = direction * -90
		
		if type == POIData.POILocationType.WALL_FEATURE:
			for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var nx = x + dir.x
				var ny = y + dir.y
				if not TileAnalyzer._is_in_bounds(nx, ny, p_params.level_size) or not p_params.grid[nx][ny].is_floor:
					p_poi.position += Vector3(dir.x, 0, dir.y) * 2.0
					break