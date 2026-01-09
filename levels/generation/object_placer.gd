# /levels/generation/object_placer.gd
# Places all the 3D objects (floors, walls, POIs, items) into the scene.
class_name ObjectPlacer
extends Object

# Main placement function, called by the generator.
func place_all_objects(p_parent: Node3D, p_params: Dictionary):
	_place_prefabs(p_parent, p_params.rooms)
	_place_floors(p_parent, p_params)
	
	# REFACTOR: Unified placement system.
	# Pass 1: Place objects that must replace wall segments first.
	var occupied_wall_edges = _place_wall_replacements(p_parent, p_params)
	
	# Now that wall openings are registered, place the actual walls.
	_place_walls(p_parent, p_params, occupied_wall_edges)
	
	# Pass 2: Place all other objects (in rooms, corridors, etc.).
	_place_standard_placeables(p_parent, p_params)
	
	_place_dark_cubes(p_parent, p_params)

# --- PLACEMENT PASSES ---

# PASS 1: Find and place all objects configured as WALL_REPLACEMENT.
func _place_wall_replacements(p_parent: Node3D, p_params: Dictionary) -> Dictionary:
	var occupied_wall_edges: Dictionary = {}
	for placeable_def in p_params.placeable_defs:
		if placeable_def.location != PlaceableData.Location.WALL_REPLACEMENT:
			continue

		if placeable_def.scene == null: continue

		for x in range(p_params.level_size.x):
			for y in range(p_params.level_size.y):
				var tile: LevelTileData = p_params.grid[x][y]

				if tile.is_prefab or tile.is_doorway: continue
				
				if not tile.is_wall_adjacent or not tile.is_floor: continue
				
				if p_params.rng.randf() >= placeable_def.density: continue
				
				var obj = placeable_def.scene.instantiate()
				p_parent.add_child(obj)
				obj.position = Vector3(x * 4 + 2, placeable_def.y_offset, y * 4 + 2)
				
				_align_placeable(obj, x, y, placeable_def, p_params, occupied_wall_edges)

	return occupied_wall_edges

# PASS 2: Find and place all objects NOT handled in other passes.
func _place_standard_placeables(p_parent: Node3D, p_params: Dictionary):
	for placeable_def in p_params.placeable_defs:
		if placeable_def.location == PlaceableData.Location.WALL_REPLACEMENT:
			continue

		if placeable_def.scene == null: continue
		
		for x in range(p_params.level_size.x):
			for y in range(p_params.level_size.y):
				var tile: LevelTileData = p_params.grid[x][y]

				if tile.is_prefab or tile.is_doorway or not tile.is_floor: continue

				if _can_place(placeable_def, tile):
					if p_params.rng.randf() < placeable_def.density:
						var obj = placeable_def.scene.instantiate()
						p_parent.add_child(obj)
						obj.position = Vector3(x * 4 + 2, placeable_def.y_offset, y * 4 + 2)
						_align_placeable(obj, x, y, placeable_def, p_params)

# --- CORE LOGIC & HELPERS ---

func _can_place(p_def: PlaceableData, p_tile: LevelTileData) -> bool:
	match p_def.location:
		PlaceableData.Location.ROOM:
			if not p_tile.is_room: return false
			match p_def.room_sub_location:
				PlaceableData.RoomSubLocation.ANY:
					return true
				PlaceableData.RoomSubLocation.OPEN_SPACE:
					return not p_tile.is_corner and not p_tile.is_wall_adjacent
				PlaceableData.RoomSubLocation.CORNER:
					return p_tile.is_corner
				PlaceableData.RoomSubLocation.WALL_ADJACENT:
					return p_tile.is_wall_adjacent
		PlaceableData.Location.CORRIDOR:
			return p_tile.is_corridor
		PlaceableData.Location.WALL_ADJACENT:
			return p_tile.is_wall_adjacent and p_tile.is_floor
	return false

func _align_placeable(p_obj: Node3D, x: int, y: int, p_def: PlaceableData, p_params: Dictionary, r_occupied_wall_edges: Dictionary = {}):
	if p_def.location == PlaceableData.Location.WALL_REPLACEMENT:
		for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var nx = x + dir.x
			var ny = y + dir.y
			if not TileAnalyzer._is_in_bounds(nx, ny, p_params.level_size) or not p_params.grid[nx][ny].is_floor:
				var look_target = p_obj.position + Vector3(dir.x, 0, dir.y) 
				p_obj.look_at(look_target, Vector3.UP)
				var edge_pos = p_obj.position + Vector3(dir.x, 0, dir.y) * 2.0
				p_obj.position = edge_pos
				r_occupied_wall_edges[Vector3i(int(edge_pos.x), 0, int(edge_pos.z))] = true
				return

	match p_def.rotation_type:
		PlaceableData.RotationType.FIXED:
			p_obj.rotation_degrees.y = p_def.fixed_direction * -90
		PlaceableData.RotationType.RANDOM_360:
			p_obj.rotation.y = p_params.rng.randf() * TAU
		PlaceableData.RotationType.RANDOM_90_DEG:
			p_obj.rotation_degrees.y = p_params.rng.randi_range(0, 3) * 90.0
		PlaceableData.RotationType.ALIGN_TO_CONTEXT:
			if p_def.location == PlaceableData.Location.CORRIDOR:
				var up = y + 1 < p_params.level_size.y and p_params.grid[x][y+1].is_floor
				var down = y - 1 >= 0 and p_params.grid[x][y-1].is_floor
				var left = x - 1 >= 0 and p_params.grid[x-1][y].is_floor
				var right = x + 1 < p_params.level_size.x and p_params.grid[x+1][y].is_floor
				
				if (left and right) and not (up or down):
					p_obj.rotation_degrees.y = [90, -90][p_params.rng.randi_range(0, 1)]
				elif (up and down) and not (left or right):
					p_obj.rotation_degrees.y = [0, 180][p_params.rng.randi_range(0, 1)]
			
			elif p_def.location == PlaceableData.Location.WALL_ADJACENT or (p_def.location == PlaceableData.Location.ROOM and p_def.room_sub_location == PlaceableData.RoomSubLocation.WALL_ADJACENT):
				for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
					var nx = x + dir.x
					var ny = y + dir.y
					if not TileAnalyzer._is_in_bounds(nx, ny, p_params.level_size) or not p_params.grid[nx][ny].is_floor:
						p_obj.look_at(p_obj.position - Vector3(dir.x, 0, dir.y), Vector3.UP)
						break
			
			elif p_def.location == PlaceableData.Location.ROOM and p_def.room_sub_location == PlaceableData.RoomSubLocation.CORNER:
				var wall_dir_sum = Vector2i.ZERO
				for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
					var nx = x + dir.x
					var ny = y + dir.y
					if not TileAnalyzer._is_in_bounds(nx, ny, p_params.level_size) or not p_params.grid[nx][ny].is_floor:
						wall_dir_sum += dir
				if wall_dir_sum != Vector2i.ZERO:
					p_obj.look_at(p_obj.position - Vector3(wall_dir_sum.x, 0, wall_dir_sum.y), Vector3.UP)

func _place_prefabs(p_parent: Node3D, p_rooms: Array):
	for room in p_rooms:
		if room.prefab_scene:
			var prefab_instance = room.prefab_scene.instantiate()
			var pos = Vector3(room.rect.position.x * 4, 0, room.rect.position.y * 4)
			var offset = Vector3(room.rect.size.x * 2.0, 0, room.rect.size.y * 2.0)
			prefab_instance.position = pos + offset
			prefab_instance.rotation_degrees.y = room.rotation_dir * -90
			p_parent.add_child(prefab_instance)

func _place_floors(p_parent: Node3D, p_params: Dictionary):
	for x in range(p_params.level_size.x):
		for y in range(p_params.level_size.y):
			var tile: LevelTileData = p_params.grid[x][y]
			if tile.is_floor and not tile.is_prefab:
				var floor_tile = p_params.floor_scene.instantiate()
				floor_tile.position = Vector3(x * 4 + 2, 0, y * 4 + 2)
				p_parent.add_child(floor_tile)

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

func _place_dark_cubes(p_parent: Node3D, p_params: Dictionary):
	for x in range(p_params.level_size.x):
		for y in range(p_params.level_size.y):
			var tile: LevelTileData = p_params.grid[x][y]
			if not tile.is_floor and not tile.is_prefab:
				var void_cube = p_params.void_cube_scene.instantiate()
				void_cube.position = Vector3(x*4+2, 2.05, y*4+2)
				p_parent.add_child(void_cube)
