extends Node3D

# Phased Procedural Level Generator for Capsule Shooters
# 1. Generate rooms (rectangular, random MxN, grid-based)
# 2. Generate corridors to connect rooms
# 3. Place floor tiles
# 4. Place walls on all exposed edges
# 5. (Extend) Place items, traps, enemies, spawn, etc.


class_name ProceduralLevelGenerator

class LevelTileData:
	var is_floor = false
	var is_wall = false
	var is_corridor = false
	var is_room = false
	# Add properties to identify tile characteristics
	var is_corner = false
	var is_surrounded = false
	var neighbor_count = 0
	var is_doorway = false
	var is_wall_adjacent = false

# Base scenes for tiles
@export var floor_scene: PackedScene
@export var wall_scene: PackedScene

# Level generation parameters
@export var level_size: Vector2i = Vector2i(32, 32) # grid size in tiles
@export var min_room_size: Vector2i = Vector2i(4, 4)
@export var max_room_size: Vector2i = Vector2i(10, 10)
@export var room_count: int = 8
@export var rn_seed: int = 0

# List of item definitions to spawn
@export var item_defs: Array[PlaceableItemData] = [] # Array[Dictionary] with keys: scene, density, location_type

var _rng: RandomNumberGenerator
var _grid: Array = [] # 2D array for tile occupancy
var _rooms: Array = [] # List of placed rooms
var _corridors: Array = [] # List of corridor tiles

class Room:
	var rect: Rect2i
	func _init(_rect):
		self.rect = _rect

func _ready():
	_rng = RandomNumberGenerator.new()
	if rn_seed != 0:
		_rng.seed = rn_seed
	_generate_level()

func _generate_level():
	_init_grid()
	_generate_rooms()
	_generate_corridors()
	_analyze_tiles()
	_place_floors()
	_place_walls()
	_place_items()
	# Extension: _place_enemies(), etc.
# Place items in rooms or corridors based on density and type
func _place_items():
	for item_def in item_defs:
		var scene = item_def.use_scene
		if scene == null:
			continue
			
		var density = item_def.density
		var location_type = item_def.location_type
		var room_location = item_def.room_location

		for x in range(level_size.x):
			for y in range(level_size.y):
				var tile_data = _grid[x][y]

				if not tile_data.is_floor or tile_data.is_doorway:
					continue

				var can_place = false
				if location_type == PlaceableItemData.PlaceableLocationType.ROOM_TILE and tile_data.is_room:
					if room_location == PlaceableItemData.RoomLocationType.CORNER and tile_data.is_corner:
						can_place = true
					elif room_location == PlaceableItemData.RoomLocationType.WALL and tile_data.is_wall_adjacent:
						can_place = true
					elif room_location == PlaceableItemData.RoomLocationType.OPEN_SPACE and not tile_data.is_corner and not tile_data.is_wall_adjacent:
						can_place = true

				elif location_type == PlaceableItemData.PlaceableLocationType.CORRIDOR_TILE and tile_data.is_corridor:
					can_place = true
				
				if can_place and _rng.randf() < density:
					var item = scene.instantiate()
					item.position = Vector3(x * 4, 1, y * 4)
					add_child(item)

func _init_grid():
	_grid.clear()
	for x in range(level_size.x):
		_grid.append([])
		for y in range(level_size.y):
			_grid[x].append(LevelTileData.new())

func _generate_rooms():
	_rooms.clear()
	var attempts = 0
	while _rooms.size() < room_count and attempts < room_count * 10:
		var w = _rng.randi_range(min_room_size.x, max_room_size.x)
		var h = _rng.randi_range(min_room_size.y, max_room_size.y)
		var x = _rng.randi_range(1, level_size.x - w - 2)
		var y = _rng.randi_range(1, level_size.y - h - 2)
		var new_rect = Rect2i(x, y, w, h)
		var overlaps = false
		for room in _rooms:
			if room.rect.grow(1).intersects(new_rect):
				overlaps = true
				break
		if not overlaps:
			_rooms.append(Room.new(new_rect))
			for i in range(w):
				for j in range(h):
					var tile_data = _grid[x+i][y+j]
					tile_data.is_floor = true
					tile_data.is_room = true
		attempts += 1

func _generate_corridors():
	_corridors.clear()
	if _rooms.size() < 2:
		return
	print("Connecting rooms with corridors...")
	for i in range(1, _rooms.size()):
		var a = _rooms[i-1].rect.get_center()
		var b = _rooms[i].rect.get_center()
		print("Connecting room", i-1, "at", a, "to room", i, "at", b)
		_connect_points(a, b)

func _analyze_tiles():
	for x in range(level_size.x):
		for y in range(level_size.y):
			var tile_data = _grid[x][y]
			if tile_data.is_floor:
				var neighbor_count = 0
				# Check 8 neighbors
				for i in range(-1, 2):
					for j in range(-1, 2):
						if i == 0 and j == 0:
							continue
						var nx = x + i
						var ny = y + j
						if nx >= 0 and nx < level_size.x and ny >= 0 and ny < level_size.y and _grid[nx][ny].is_floor:
							neighbor_count += 1
				
				tile_data.neighbor_count = neighbor_count
				
				if neighbor_count == 8:
					tile_data.is_surrounded = true
				
				var wall_count = 0
				for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
					var nx = x + dir.x
					var ny = y + dir.y
					if nx < 0 or ny < 0 or nx >= level_size.x or ny >= level_size.y or not _grid[nx][ny].is_floor:
						wall_count += 1

				if wall_count == 1:
					tile_data.is_wall_adjacent = true
				elif wall_count == 2:
					var north_is_wall = (y - 1 < 0 or not _grid[x][y-1].is_floor)
					var south_is_wall = (y + 1 >= level_size.y or not _grid[x][y+1].is_floor)
					var east_is_wall = (x + 1 >= level_size.x or not _grid[x+1][y].is_floor)
					var west_is_wall = (x - 1 < 0 or not _grid[x-1][y].is_floor)
					if (north_is_wall and east_is_wall) or \
					   (north_is_wall and west_is_wall) or \
					   (south_is_wall and east_is_wall) or \
					   (south_is_wall and west_is_wall):
						tile_data.is_corner = true
				elif wall_count > 2:
					tile_data.is_corner = true
				
				if tile_data.is_room:
					for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
						var nx = x + dir.x
						var ny = y + dir.y
						if nx >= 0 and nx < level_size.x and ny >= 0 and ny < level_size.y and _grid[nx][ny].is_corridor:
							tile_data.is_doorway = true
							break

func _connect_points(a: Vector2i, b: Vector2i):
	var x = a.x
	var y = a.y
	while x != b.x:
		var tile_data = _grid[x][y]
		if not tile_data.is_floor:
			tile_data.is_floor = true
			tile_data.is_corridor = true
		if not Vector2i(x, y) in _corridors:
			_corridors.append(Vector2i(x, y))
			print("Corridor tile:", x, y)
		x += 1 if b.x > x else -1
	while y != b.y:
		var tile_data = _grid[x][y]
		if not tile_data.is_floor:
			tile_data.is_floor = true
			tile_data.is_corridor = true
		if not Vector2i(x, y) in _corridors:
			_corridors.append(Vector2i(x, y))
			print("Corridor tile:", x, y)
		y += 1 if b.y > y else -1

func _place_floors():
	for x in range(level_size.x):
		for y in range(level_size.y):
			if _grid[x][y].is_floor:
				var floor_tile = floor_scene.instantiate()
				floor_tile.position = Vector3(x*4, 0, y*4)
				add_child(floor_tile)

func _place_walls():
	print("Rooms:", _rooms.size(), "Corridors:", _corridors.size())
	for x in range(level_size.x):
		for y in range(level_size.y):
			if _grid[x][y].is_floor:
				for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
					var nx = x + dir.x
					var ny = y + dir.y
					# Place wall if neighbor is outside grid, or is not an occupied tile
					if nx < 0 or ny < 0 or nx >= level_size.x or ny >= level_size.y or not _grid[nx][ny].is_floor:
						var wall = wall_scene.instantiate()
						wall.position = Vector3((x+dir.x/2.0)*4, 0, (y+dir.y/2.0)*4)
						if dir.x != 0:
							wall.rotation.y = deg_to_rad(90)
						add_child(wall)

# Extension points:
# - Add _place_items(), _place_enemies(), _place_traps(), etc.
# - Add more advanced corridor/room connection logic
# - Add support for different module types
# - Add hooks for post-processing (lighting, nav, etc.)
