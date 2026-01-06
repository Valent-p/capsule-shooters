extends Node3D

# Phased Procedural Level Generator for Capsule Shooters
# 1. Generate rooms (rectangular, random MxN, grid-based)
# 2. Generate corridors to connect rooms
# 3. Place floor tiles
# 4. Place walls on all exposed edges
# 5. (Extend) Place items, traps, enemies, spawn, etc.

class_name ProceduralLevelGenerator

@export var floor_scene: PackedScene
@export var wall_scene: PackedScene
@export var level_size: Vector2i = Vector2i(32, 32) # grid size in tiles
@export var min_room_size: Vector2i = Vector2i(4, 4)
@export var max_room_size: Vector2i = Vector2i(10, 10)
@export var room_count: int = 8
@export var rn_seed: int = 0

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
		_rng.rn_seed = rn_seed
	_generate_level()

func _generate_level():
	_init_grid()
	_generate_rooms()
	_generate_corridors()
	_place_floors()
	_place_walls()
	# Extension: _place_items(), _place_enemies(), etc.

func _init_grid():
	_grid.clear()
	for x in range(level_size.x):
		_grid.append([])
		for y in range(level_size.y):
			_grid[x].append(false)

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
					_grid[x+i][y+j] = true
		attempts += 1

func _generate_corridors():
	_corridors.clear()
	if _rooms.size() < 2:
		return
	# Connect each room to the previous (simple MST/chain)
	for i in range(1, _rooms.size()):
		var a = _rooms[i-1].rect.get_center()
		var b = _rooms[i].rect.get_center()
		_connect_points(a, b)

func _connect_points(a: Vector2i, b: Vector2i):
	var x = a.x
	var y = a.y
	while x != b.x:
		_grid[x][y] = true
		_corridors.append(Vector2i(x, y))
		x += 1 if b.x > x else -1
	while y != b.y:
		_grid[x][y] = true
		_corridors.append(Vector2i(x, y))
		y += 1 if b.y > y else -1

func _place_floors():
	for x in range(level_size.x):
		for y in range(level_size.y):
			if _grid[x][y]:
				var floor_tile = floor_scene.instantiate()
				floor_tile.position = Vector3(x*4, 0, y*4)
				add_child(floor_tile)

func _place_walls():
	for x in range(level_size.x):
		for y in range(level_size.y):
			if _grid[x][y]:
				for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
					var nx = x + dir.x
					var ny = y + dir.y
					if nx < 0 or ny < 0 or nx >= level_size.x or ny >= level_size.y or not _grid[nx][ny]:
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
