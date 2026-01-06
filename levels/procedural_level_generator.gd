extends Node3D

# Phased Procedural Level Generator for Capsule Shooters
# 1. Generate rooms (rectangular, random MxN, grid-based)
# 2. Generate corridors to connect rooms
# 3. Place floor tiles
# 4. Place walls on all exposed edges
# 5. (Extend) Place items, traps, enemies, spawn, etc.


class_name ProceduralLevelGenerator

# Base scenes for tiles
@export var floor_scene: PackedScene
@export var wall_scene: PackedScene
@export var door_scene: PackedScene # Door (same size as wall)

# Level generation parameters
@export var level_size: Vector2i = Vector2i(32, 32) # grid size in tiles
@export var min_room_size: Vector2i = Vector2i(4, 4)
@export var max_room_size: Vector2i = Vector2i(10, 10)
@export var room_count: int = 8
@export var rn_seed: int = 0


# Item definition for procedural placement
class ItemDef:
	var scene: PackedScene
	var density: float
	var location_type: String # "room" or "corridor"
	func _init(_scene, _density, _location_type):
		scene = _scene
		density = _density
		location_type = _location_type

# List of item definitions to spawn
@export var item_defs: Array = [] # Array[Dictionary] with keys: scene, density, location_type

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
	_place_items()
	# Extension: _place_enemies(), etc.
# Place items in rooms or corridors based on density and type
func _place_items():
	for item_def in item_defs:
		var scene = null
		var density = 0.05
		var location_type = "room"
		if typeof(item_def) == TYPE_DICTIONARY:
			scene = item_def.get("scene", null)
			density = item_def.get("density", 0.05)
			location_type = item_def.get("location_type", "room")
		else:
			scene = item_def.scene
			density = item_def.density
			location_type = item_def.location_type
		if scene == null:
			continue
		var possible_tiles = []
		if location_type == "room":
			for room in _rooms:
				for x in range(room.rect.position.x, room.rect.position.x + room.rect.size.x):
					for y in range(room.rect.position.y, room.rect.position.y + room.rect.size.y):
						possible_tiles.append(Vector2i(x, y))
		elif location_type == "corridor":
			possible_tiles = _corridors.duplicate()
		for tile in possible_tiles:
			if _rng.randf() < density:
				var item = scene.instantiate()
				item.position = Vector3(tile.x * 4, 0, tile.y * 4)
				add_child(item)

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
	print("Connecting rooms with corridors...")
	for i in range(1, _rooms.size()):
		var a = _rooms[i-1].rect.get_center()
		var b = _rooms[i].rect.get_center()
		print("Connecting room", i-1, "at", a, "to room", i, "at", b)
		_connect_points(a, b)

func _connect_points(a: Vector2i, b: Vector2i):
	var x = a.x
	var y = a.y
	while x != b.x:
		_grid[x][y] = true
		if not Vector2i(x, y) in _corridors:
			_corridors.append(Vector2i(x, y))
			print("Corridor tile:", x, y)
		x += 1 if b.x > x else -1
	while y != b.y:
		_grid[x][y] = true
		if not Vector2i(x, y) in _corridors:
			_corridors.append(Vector2i(x, y))
			print("Corridor tile:", x, y)
		y += 1 if b.y > y else -1

func _place_floors():
	for x in range(level_size.x):
		for y in range(level_size.y):
			if _grid[x][y]:
				var floor_tile = floor_scene.instantiate()
				floor_tile.position = Vector3(x*4, 0, y*4)
				add_child(floor_tile)

func _place_walls():
	print("Rooms:", _rooms.size(), "Corridors:", _corridors.size())
	for x in range(level_size.x):
		for y in range(level_size.y):
			if _grid[x][y]:
				for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
					var nx = x + dir.x
					var ny = y + dir.y
					var here = Vector2i(x, y)
					var neighbor = Vector2i(nx, ny)
					var is_room = false
					var is_neighbor_room = false
					var is_corridor = false
					var is_neighbor_corridor = false
					# Is current tile a room?
					for room in _rooms:
						if room.rect.has_point(here):
							is_room = true
						if room.rect.has_point(neighbor):
							is_neighbor_room = true
					# Is current/neighbor a corridor?
					if here in _corridors:
						is_corridor = true
					if neighbor in _corridors:
						is_neighbor_corridor = true
					# Place door only if current is room, neighbor is corridor, and neighbor is not a room
					var use_door = false
					if door_scene != null and is_room and is_neighbor_corridor and not is_neighbor_room:
						use_door = true
					# Place wall only if neighbor is not a room and not a corridor and is inside grid
					var place_wall = false
					if not use_door and (nx < 0 or ny < 0 or nx >= level_size.x or ny >= level_size.y or (not is_neighbor_room and not is_neighbor_corridor)):
						place_wall = true
					if use_door or place_wall:
						var wall_or_door = door_scene.instantiate() if use_door else wall_scene.instantiate()
						wall_or_door.position = Vector3((x+dir.x/2.0)*4, 0, (y+dir.y/2.0)*4)
						if dir.x != 0:
							wall_or_door.rotation.y = deg_to_rad(90)
						add_child(wall_or_door)
						if use_door:
							print("Placed door at:", x, y, "dir:", dir, "room:", is_room, "neighbor_corridor:", is_neighbor_corridor, "neighbor_room:", is_neighbor_room)

# Extension points:
# - Add _place_items(), _place_enemies(), _place_traps(), etc.
# - Add more advanced corridor/room connection logic
# - Add support for different module types
# - Add hooks for post-processing (lighting, nav, etc.)
