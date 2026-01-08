extends Node3D

# Phased Procedural Level Generator for Capsule Shooters
class_name ProceduralLevelGenerator

class LevelTileData:
	var is_floor = false
	var is_wall = false
	var is_corridor = false
	var is_room = false
	var is_prefab = false
	var room_id = -1
	# Add properties to identify tile characteristics
	var is_corner = false
	var is_surrounded = false
	var neighbor_count = 0
	var is_doorway = false
	var is_wall_adjacent = false

# Base scenes for tiles
@export var floor_scene: PackedScene
@export var wall_scene: PackedScene
@export var void_cube_scene: PackedScene

# Level generation parameters
@export var level_size: Vector2i = Vector2i(32, 32) # grid size in tiles
@export var min_room_size: Vector2i = Vector2i(4, 4)
@export var max_room_size: Vector2i = Vector2i(10, 10)
@export var room_count: int = 8
@export var rn_seed: int = 0
@export var prefab_chance: float = 0.25

# List of definitions
@export var prefab_defs: Array[PrefabItemData] = []
@export var item_defs: Array[PlaceableItemData] = [] 
@export var poi_defs: Array[POIData] = []

var _rng: RandomNumberGenerator
var _grid: Array = [] # 2D array for tile occupancy
var _rooms: Array = [] # List of placed rooms
var _corridors: Array = [] # List of corridor tiles

# FIXED: Stores exact edge positions (Vector3i) where a wall has been replaced by a POI
# This prevents "Holes" in walls shared by two rooms.
var _occupied_wall_edges: Dictionary = {}

class Room:
	var id: int
	var rect: Rect2i
	var prefab_scene: PackedScene = null
	var density_modifier: float = 1.0
	var distance_from_spawn: int = -1
	var rotation_dir: PrefabItemData.Direction
	
	# Store entrances in Global Grid Coordinates
	var global_entrances: Array[Vector2i] = []
	
	func _init(_id, _rect, _prefab_scene = null, _rot: PrefabItemData.Direction = PrefabItemData.Direction.NORTH):
		self.id = _id
		self.rect = _rect
		self.prefab_scene = _prefab_scene
		self.rotation_dir = _rot
		
	# Helper to get the best entrance point relative to a target room
	func get_connection_point(target_center: Vector2) -> Vector2i:
		if prefab_scene == null:
			return rect.get_center()
		if global_entrances.is_empty():
			return rect.get_center()
			
		var best_point = global_entrances[0]
		var min_dist = Vector2(best_point).distance_squared_to(target_center)
		for point in global_entrances:
			var d = Vector2(point).distance_squared_to(target_center)
			if d < min_dist:
				min_dist = d
				best_point = point
		return best_point
		
func _ready():
	_rng = RandomNumberGenerator.new()
	if rn_seed != 0:
		_rng.seed = rn_seed
	_generate_level()

func _generate_level():
	_occupied_wall_edges.clear() # Reset tracking
	
	_init_grid()
	_generate_rooms()
	_generate_corridors()
	_calculate_room_distances()
	_analyze_tiles()
	
	_place_prefabs()
	_place_floors()
	
	# Place POIs BEFORE walls so they can register occupied edges
	_place_pois()
	
	_place_walls()
	_place_items()
	
	_place_dark_cubes()
	# _debug_draw_rooms()

# --- GENERATION STEPS ---

func _init_grid():
	_grid.clear()
	for x in range(level_size.x):
		_grid.append([])
		for y in range(level_size.y):
			_grid[x].append(LevelTileData.new())

func _generate_unique_prefabs(current_room_id: int):
	for prefab in prefab_defs.duplicate():
		if prefab.unique:
			# Remove to make sure we don't place it again
			prefab_defs.erase(prefab)

			var w: int
			var h: int
			var chosen_dir: PrefabItemData.Direction
			# 1. Decide Rotation
			if prefab.randomize_rotation:
				chosen_dir = _rng.randi_range(0, 3) as PrefabItemData.Direction
			else:
				chosen_dir = prefab.fixed_direction
			# 2. Calculate Dimensions (Swap if East/West)
			if chosen_dir == PrefabItemData.Direction.EAST or chosen_dir == PrefabItemData.Direction.WEST:
				w = prefab.height
				h = prefab.width
			else:
				w = prefab.width
				h = prefab.height
			# 3. Find Spot
			var placed = false
			var attempts = 0
			while not placed and attempts < 100:
				var x = _rng.randi_range(1, level_size.x - w - 2)
				var y = _rng.randi_range(1, level_size.y - h - 2)
				var new_rect = Rect2i(x, y, w, h)
				var overlaps = false
				for room in _rooms:
					if room.rect.grow(1).intersects(new_rect):
						overlaps = true
						break
				if not overlaps:
					var new_room = Room.new(current_room_id, new_rect, prefab.prefab_scene, chosen_dir)
					# Calculate Global Entrances based on Rotation
					for entrance_local in prefab.entrances:
						var rotated_entrance = _rotate_point(entrance_local, chosen_dir, prefab.width, prefab.height)
						var global_pos = new_rect.position + rotated_entrance
						new_room.global_entrances.append(global_pos)
					_rooms.append(new_room)
					# Mark Grid
					for i in range(w):
						for j in range(h):
							var tile_data = _grid[x+i][y+j]
							tile_data.is_floor = true
							tile_data.is_room = true
							tile_data.is_prefab = true
							tile_data.room_id = current_room_id
					current_room_id += 1
					placed = true
				attempts += 1

func _generate_rooms():
	_rooms.clear()
	var attempts = 0
	var current_room_id = 0

	# NOTE: All unique prefabs MUST be placed no matter what, but only once.
	_generate_unique_prefabs(current_room_id)
	current_room_id = _rooms.size()

	while _rooms.size() < room_count and attempts < room_count * 10:
		var w: int
		var h: int
		var prefab_to_place: PrefabItemData = null
		var chosen_dir: PrefabItemData.Direction
		
		if _rng.randf() < prefab_chance and prefab_defs.size() > 0:
			prefab_to_place = prefab_defs.pick_random()

			# Remove it from list if unique
			if prefab_to_place.unique:
				prefab_defs.erase(prefab_to_place)
			
			# 1. Decide Rotation
			if prefab_to_place.randomize_rotation:
				chosen_dir = _rng.randi_range(0, 3) as PrefabItemData.Direction
			else:
				chosen_dir = prefab_to_place.fixed_direction
			
			# 2. Calculate Dimensions (Swap if East/West)
			if chosen_dir == PrefabItemData.Direction.EAST or chosen_dir == PrefabItemData.Direction.WEST:
				w = prefab_to_place.height
				h = prefab_to_place.width
			else:
				w = prefab_to_place.width
				h = prefab_to_place.height
		else:
			w = _rng.randi_range(min_room_size.x, max_room_size.x)
			h = _rng.randi_range(min_room_size.y, max_room_size.y)
			
		# 3. Find Spot (Add buffer to avoid edge-of-map doors)
		var x = _rng.randi_range(1, level_size.x - w - 2)
		var y = _rng.randi_range(1, level_size.y - h - 2)
		
		var new_rect = Rect2i(x, y, w, h)
		var overlaps = false
		
		for room in _rooms:
			if room.rect.grow(1).intersects(new_rect):
				overlaps = true
				break
				
		if not overlaps:
			var new_room: Room
			if prefab_to_place:
				new_room = Room.new(current_room_id, new_rect, prefab_to_place.prefab_scene, chosen_dir)
				
				# Calculate Global Entrances based on Rotation
				for entrance_local in prefab_to_place.entrances:
					# Pass ORIGINAL width/height to rotation helper
					var rotated_entrance = _rotate_point(entrance_local, chosen_dir, prefab_to_place.width, prefab_to_place.height)
					var global_pos = new_rect.position + rotated_entrance
					new_room.global_entrances.append(global_pos)
			else:
				new_room = Room.new(current_room_id, new_rect)
			
			# Check Validity (Are doors blocked?)
			var valid_placement = true
			if prefab_to_place:
				valid_placement = false
				for door_pos in new_room.global_entrances:
					for dir in [Vector2i(0,1), Vector2i(0,-1), Vector2i(1,0), Vector2i(-1,0)]:
						var check_pos = door_pos + dir
						if check_pos.x >= 0 and check_pos.x < level_size.x and check_pos.y >= 0 and check_pos.y < level_size.y:
							if not _grid[check_pos.x][check_pos.y].is_room:
								valid_placement = true
								break
					if valid_placement: break
			
			if valid_placement:
				new_room.density_modifier = _rng.randf_range(0.5, 1.5)
				
				_rooms.append(new_room)
				
				# Mark Grid
				for i in range(w):
					for j in range(h):
						var tile_data = _grid[x+i][y+j]
						tile_data.is_floor = true
						tile_data.is_room = true
						tile_data.room_id = current_room_id
						if prefab_to_place: tile_data.is_prefab = true
				current_room_id += 1
		attempts += 1

func _rotate_point(point: Vector2i, dir: int, original_w: int, original_h: int) -> Vector2i:
	match dir:
		PrefabItemData.Direction.NORTH: return point
		PrefabItemData.Direction.EAST: return Vector2i(original_h - 1 - point.y, point.x)
		PrefabItemData.Direction.SOUTH: return Vector2i(original_w - 1 - point.x, original_h - 1 - point.y)
		PrefabItemData.Direction.WEST: return Vector2i(point.y, original_w - 1 - point.x)
	return point

func _generate_corridors():
	_corridors.clear()
	if _rooms.size() < 2: return
	
	var astar = AStar2D.new()
	
	# Add points
	for x in range(level_size.x):
		for y in range(level_size.y):
			var idx = y * level_size.x + x
			var tile = _grid[x][y]
			var weight = 1.0
			
			if tile.is_room:
				if tile.is_prefab:
					# Only entrances are walkable in prefabs
					var is_entrance = false
					if tile.room_id != -1:
						var room = _rooms[tile.room_id]
						if Vector2i(x, y) in room.global_entrances:
							is_entrance = true
					
					if is_entrance: weight = 1.0 
					else:
						astar.add_point(idx, Vector2(x, y), weight)
						astar.set_point_disabled(idx, true) 
						continue 
				else:
					weight = 5.0 
			
			astar.add_point(idx, Vector2(x, y), weight)

	# Connect grid
	for x in range(level_size.x):
		for y in range(level_size.y):
			var idx1 = y * level_size.x + x
			for dir in [Vector2i(1,0), Vector2i(0,1)]: 
				var nx = x + dir.x
				var ny = y + dir.y
				if nx < level_size.x and ny < level_size.y:
					var idx2 = ny * level_size.x + nx
					if not astar.is_point_disabled(idx1) and not astar.is_point_disabled(idx2):
						astar.connect_points(idx1, idx2, true)

	# Pathfind
	for i in range(1, _rooms.size()):
		var room_a = _rooms[i-1]
		var room_b = _rooms[i]
		
		var start_pos_vec = room_a.get_connection_point(room_b.rect.get_center())
		var end_pos_vec = room_b.get_connection_point(room_a.rect.get_center())
		
		var start_idx = start_pos_vec.y * level_size.x + start_pos_vec.x
		var end_idx = end_pos_vec.y * level_size.x + end_pos_vec.x
		
		var path_points = astar.get_point_path(start_idx, end_idx)
		
		if path_points.is_empty():
			print("Warning: Could not connect Room ", i-1, " to Room ", i)
			continue
			
		for point_pos in path_points:
			var px = int(point_pos.x)
			var py = int(point_pos.y)
			var tile_data = _grid[px][py]
			if not tile_data.is_floor:
				tile_data.is_floor = true
				tile_data.is_corridor = true
			if not Vector2i(px, py) in _corridors:
				_corridors.append(Vector2i(px, py))

func _analyze_tiles():
	# Standard 8-neighbor and wall-count analysis
	for x in range(level_size.x):
		for y in range(level_size.y):
			var tile_data = _grid[x][y]
			if not tile_data.is_floor:
				# Check if it should be a wall
				for i in range(-1, 2):
					for j in range(-1, 2):
						if i == 0 and j == 0: continue
						var nx = x + i
						var ny = y + j
						if nx >= 0 and nx < level_size.x and ny >= 0 and ny < level_size.y and _grid[nx][ny].is_floor:
							tile_data.is_wall = true
							break
					if tile_data.is_wall: break
				continue
			
			# Floor Analysis
			var neighbor_count = 0
			for i in range(-1, 2):
				for j in range(-1, 2):
					if i == 0 and j == 0: continue
					var nx = x + i
					var ny = y + j
					if nx >= 0 and nx < level_size.x and ny >= 0 and ny < level_size.y and _grid[nx][ny].is_floor:
						neighbor_count += 1
			tile_data.neighbor_count = neighbor_count
			if neighbor_count == 8: tile_data.is_surrounded = true
			
			var wall_count = 0
			for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
				var nx = x + dir.x
				var ny = y + dir.y
				if nx < 0 or ny < 0 or nx >= level_size.x or ny >= level_size.y or not _grid[nx][ny].is_floor:
					wall_count += 1

			if wall_count == 1: tile_data.is_wall_adjacent = true
			elif wall_count > 1: tile_data.is_corner = true # Simplified corner check
	
	# UPDATE: If a corridor is having more than 2 neighbors, mark as room tile
	for corridor_pos in _corridors:
		var x = corridor_pos.x
		var y = corridor_pos.y
		var tile_data = _grid[x][y]
		var neighbor_count = 0
		for i in range(-1, 2):
			for j in range(-1, 2):
				if i == 0 and j == 0: continue
				var nx = x + i
				var ny = y + j
				if nx >= 0 and nx < level_size.x and ny >= 0 and ny < level_size.y and _grid[nx][ny].is_floor:
					neighbor_count += 1
		if neighbor_count > 2:
			tile_data.is_room = true
			tile_data.is_corridor = false
			if tile_data.room_id == -1:
				# Assign to nearest room
				var closest_room_id = -1
				var closest_dist = INF
				for room in _rooms:
					var room_center = room.rect.get_center()
					var dist = Vector2(x, y).distance_squared_to(room_center)
					if dist < closest_dist:
						closest_dist = dist
						closest_room_id = room.id
				tile_data.room_id = closest_room_id
			tile_data.is_doorway = true


# --- PLACEMENT STEPS ---

func _place_prefabs():
	for room in _rooms:
		if room.prefab_scene:
			var prefab_instance = room.prefab_scene.instantiate()
			# Top-Left + Offset + Rotation
			var pos = Vector3(room.rect.position.x * 4, 0, room.rect.position.y * 4)
			var offset = Vector3(room.rect.size.x * 2.0, 0, room.rect.size.y * 2.0)
			prefab_instance.position = pos + offset
			prefab_instance.rotation_degrees.y = room.rotation_dir * -90
			add_child(prefab_instance)

func _place_floors():
	for x in range(level_size.x):
		for y in range(level_size.y):
			var tile_data = _grid[x][y]
			if tile_data.is_floor and not tile_data.is_prefab:
				var floor_tile = floor_scene.instantiate()
				# +2 Offset for center alignment
				floor_tile.position = Vector3(x*4+2, 0, y*4+2)
				add_child(floor_tile)

func _place_pois():
	for poi_def in poi_defs:
		var scene = poi_def.poi_scene
		if scene == null: continue
		var density = poi_def.density
		var loc_type = poi_def.location_type

		for x in range(level_size.x):
			for y in range(level_size.y):
				var tile_data = _grid[x][y]

				if tile_data.is_prefab or tile_data.is_doorway: continue
				var can_place = false
				
				# --- LOGIC UPDATES ---
				
				# 1. CORNER: Must be a corner AND inside a room (No corridors!)
				if loc_type == POIData.POILocationType.CORNER:
					if tile_data.is_corner and tile_data.is_room:
						can_place = true
						
				# 2. WALL FEATURE / BLOCK: Floor adjacent to wall
				elif loc_type == POIData.POILocationType.WALL_BLOCK or loc_type == POIData.POILocationType.WALL_FEATURE:
					if tile_data.is_wall_adjacent and tile_data.is_floor:
						can_place = true

				# 3. OPEN SPACE: Room floor, not corner, not wall
				elif loc_type == POIData.POILocationType.OPEN_SPACE:
					if not tile_data.is_corner and not tile_data.is_wall_adjacent and tile_data.is_room:
						can_place = true
						
				# 4. CORRIDOR: Explicitly corridor tiles
				elif loc_type == POIData.POILocationType.CORRIDOR_TILE:
					if tile_data.is_corridor:
						can_place = true
				
				if not can_place: continue
				if _rng.randf() >= density: continue

				# --- PLACEMENT ---
				var poi = scene.instantiate()
				add_child(poi)
				poi.position = Vector3(x * 4 + 2, poi_def.offset_y, y * 4 + 2)
				
				if loc_type == POIData.POILocationType.WALL_BLOCK:
					_align_and_register_wall_block(poi, x, y)
				elif loc_type == POIData.POILocationType.CORRIDOR_TILE and poi_def.direction == POIData.Direction.RANDOM:
					poi.rotation.y = _rng.randf() * TAU
				elif loc_type == POIData.POILocationType.CORRIDOR_TILE and poi_def.direction == POIData.Direction.GRID_SNAP:
					# Use linear align. if A has north and south neighbors face to south or north. If has east and west neighbors face to east or west.
					_align_poi_and_snap(poi, x, y, loc_type)
					
				else: # NORTH, WEST, EAST or SOUTH
					poi.rotation_degrees.y = poi_def.direction * -90
					if loc_type == POIData.POILocationType.WALL_FEATURE:
						_align_poi_and_snap(poi, x, y, loc_type)

func _align_and_register_wall_block(node: Node3D, x: int, y: int):
	# Finds the void neighbor, looks at it, moves POI to the edge, and registers the gap.
	for dir in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
		var nx = x + dir.x
		var ny = y + dir.y
		if nx < 0 or ny < 0 or nx >= level_size.x or ny >= level_size.y or not _grid[nx][ny].is_floor:
			# Look at wall
			var look_target = node.position + Vector3(dir.x, 0, dir.y) 
			node.look_at(look_target, Vector3.UP)
			
			# Snap to Edge (2m from center)
			var edge_pos = node.position + Vector3(dir.x, 0, dir.y) * 2.0
			node.position = edge_pos
			
			# Register position to stop wall generation here
			# We use Integer keys to avoid float precision errors
			var key = Vector3i(int(edge_pos.x), 0, int(edge_pos.z))
			_occupied_wall_edges[key] = true
			break

func _align_poi_and_snap(node: Node3D, x: int, y: int, type: POIData.POILocationType):
	if type == POIData.POILocationType.WALL_FEATURE:
		for dir in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
			var nx = x + dir.x
			var ny = y + dir.y
			if nx < 0 or ny < 0 or nx >= level_size.x or ny >= level_size.y or not _grid[nx][ny].is_floor:
				# Look AWAY from wall
				var look_target = node.position - Vector3(dir.x, 0, dir.y)
				node.look_at(look_target, Vector3.UP)
				# Snap to wall (2m)
				node.position += Vector3(dir.x, 0, dir.y) * 2.0
				break
	elif type == POIData.POILocationType.CORRIDOR_TILE:
		var left = x - 1 >= 0 and _grid[x-1][y].is_floor
		var right = x + 1 < level_size.x and _grid[x+1][y].is_floor
		var up = y + 1 < level_size.y and _grid[x][y+1].is_floor
		var down = y - 1 >= 0 and _grid[x][y-1].is_floor
		if (left and right) and not (up or down):
			# Horizontal corridor
			node.rotation_degrees.y = 90
		elif (up and down) and not (left or right):
			# Vertical corridor
			node.rotation_degrees.y = 0
	elif type == POIData.POILocationType.CORNER:
		var wall_dir_sum = Vector2i.ZERO
		for dir in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
			var nx = x + dir.x
			var ny = y + dir.y
			if nx < 0 or ny < 0 or nx >= level_size.x or ny >= level_size.y or not _grid[nx][ny].is_floor:
				wall_dir_sum += dir
		if wall_dir_sum != Vector2i.ZERO:
			var look_target = node.position - Vector3(wall_dir_sum.x, 0, wall_dir_sum.y)
			node.look_at(look_target, Vector3.UP)

func _place_walls():
	for x in range(level_size.x):
		for y in range(level_size.y):
			var tile_data = _grid[x][y]
			if tile_data.is_floor and not tile_data.is_prefab:
				for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
					var nx = x + dir.x
					var ny = y + dir.y
					# Place wall if neighbor is void
					if nx < 0 or ny < 0 or nx >= level_size.x or ny >= level_size.y or not _grid[nx][ny].is_floor:
						# Calculate exact wall position
						var wall_x = (x * 4) + 2 + (dir.x * 2)
						var wall_z = (y * 4) + 2 + (dir.y * 2)
						var key = Vector3i(wall_x, 0, wall_z)
						
						# CHECK: Is this spot taken by a POI?
						if _occupied_wall_edges.has(key):
							continue # Skip wall
						
						var wall = wall_scene.instantiate()
							
						wall.position = Vector3(wall_x, 0, wall_z)
						if dir.x != 0: wall.rotation.y = deg_to_rad(90)
						add_child(wall)

func _place_items():
	for item_def in item_defs:
		var scene = item_def.use_scene
		if scene == null: continue
		var density = item_def.density
		var location_type = item_def.location_type

		for x in range(level_size.x):
			for y in range(level_size.y):
				var tile_data = _grid[x][y]

				if tile_data.is_prefab or tile_data.is_doorway: continue
				if not tile_data.is_floor: continue # Simplified check

				# Basic location filter logic...
				var can_place = false
				# (Insert your Room/Corridor check logic here same as before)
				# For brevity, checking Room Tile logic:
				if location_type == PlaceableItemData.PlaceableLocationType.ROOM_TILE and tile_data.is_room:
					can_place = true # (Simplified for this snippet, add back your corner/wall logic)
				elif location_type == PlaceableItemData.PlaceableLocationType.CORRIDOR_TILE and tile_data.is_corridor:
					can_place = true
				
				if can_place and _rng.randf() < density:
					var item = scene.instantiate()
					item.position = Vector3(x * 4 + 2, item_def.y_offset, y * 4 + 2)
					
					# Rotation Logic
					if item_def.rotation_type == PlaceableItemData.RotationType.RANDOM:
						item.rotation.y = _rng.randf() * TAU
					elif item_def.rotation_type == PlaceableItemData.RotationType.GRID_SNAP:
						item.rotation_degrees.y = _rng.randi_range(0, 3) * 90.0
					# Add Alignment logic if needed (similar to POIs)
					
					add_child(item)

func _place_dark_cubes():
	for x in range(level_size.x):
		for y in range(level_size.y):
			var tile_data = _grid[x][y]
			if not tile_data.is_floor and not tile_data.is_prefab:
				var void_cube = void_cube_scene.instantiate()
				# +2 Offset for center alignment
				void_cube.position = Vector3(x*4+2, 2.05, y*4+2)
				add_child(void_cube)
	

func _debug_draw_rooms():
	for room in _rooms:
		# Create a visual box representing the Logical Grid Room
		var mesh_inst = MeshInstance3D.new()
		var box = BoxMesh.new()
		
		# Calculate real world size (Tile count * 4 units)
		var world_w = room.rect.size.x * 4.0
		var world_h = room.rect.size.y * 4.0
		
		box.size = Vector3(world_w, 4.0, world_h) # Height of 4 for visibility
		
		# Create a transparent red material
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1, 0, 0, 0.3) # Semi-transparent Red
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		box.material = mat
		
		mesh_inst.mesh = box
		add_child(mesh_inst)
		
		# Position the box based on Center-Point (BoxMesh uses center pivot)
		# But we calculate it relative to the Grid Top-Left
		var center_x = (room.rect.position.x * 4.0) + (world_w / 2.0)
		var center_z = (room.rect.position.y * 4.0) + (world_h / 2.0)
		
		mesh_inst.position = Vector3(center_x, 2.0, center_z)
		
		# DRAW ENTRANCES
		if room.global_entrances.size() > 0:
			for entrance_pos in room.global_entrances:
				var sphere = SphereMesh.new()
				sphere.radius = 1.0
				sphere.height = 2.0
				
				var sphere_inst = MeshInstance3D.new()
				sphere_inst.mesh = sphere
				
				var door_mat = StandardMaterial3D.new()
				door_mat.albedo_color = Color(0, 1, 0, 1.0) # Solid Green
				sphere_inst.material_override = door_mat
				
				add_child(sphere_inst)
				
				# Position at the center of the grid tile
				# (X * 4) + 2 offset we added earlier
				sphere_inst.position = Vector3(entrance_pos.x * 4 + 2, 2, entrance_pos.y * 4 + 2)

func _calculate_room_distances():
	if _rooms.is_empty():
		return

	var adj = []
	adj.resize(_rooms.size())
	for i in range(_rooms.size()):
		adj[i] = []

	for i in range(1, _rooms.size()):
		adj[i-1].append(i)
		adj[i].append(i-1)

	var queue = [[0, 0]] # (room_id, distance)
	var visited = [0]
	_rooms[0].distance_from_spawn = 0

	while not queue.is_empty():
		var current = queue.pop_front()
		var current_id = current[0]
		var current_dist = current[1]

		for neighbor_id in adj[current_id]:
			if not neighbor_id in visited:
				visited.append(neighbor_id)
				_rooms[neighbor_id].distance_from_spawn = current_dist + 1
				queue.append([neighbor_id, current_dist + 1])

# Extension points:
# - Add _place_items(), _place_enemies(), _place_traps(), etc.
# - Add more advanced corridor/room connection logic
# - Add support for different module types
# - Add hooks for post-processing (lighting, nav, etc.)
