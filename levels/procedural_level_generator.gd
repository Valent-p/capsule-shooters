# procedural_level_generator.gd
# This is the main orchestrator for the phased procedural level generator.
# It holds the parameters and calls the specialized generator modules in sequence.
class_name ProceduralLevelGenerator
extends Node3D

# --- Level Generation Parameters ---
@export_group("Dimensions")
@export var level_size: Vector2i = Vector2i(32, 32)
@export var room_count: int = 8
@export var min_room_size: Vector2i = Vector2i(4, 4)
@export var max_room_size: Vector2i = Vector2i(10, 10)

@export_group("Seeding and Randomness")
@export var rn_seed: int = 0
@export var prefab_chance: float = 0.25

@export_group("Scene Definitions")
@export var floor_scene: PackedScene
@export var wall_scene: PackedScene
@export var void_cube_scene: PackedScene

@export_group("Placeable Item Definitions")
@export var prefab_defs: Array[PrefabItemData] = []
@export var item_defs: Array[PlaceableItemData] = [] 
@export var poi_defs: Array[POIData] = []

# --- Private Generation State ---
var _rng: RandomNumberGenerator
var _grid: Array = []
var _rooms: Array[Room] = []
var _corridors: Array[Vector2i] = []

# ObjectPlacer has instance methods, so it needs to be instantiated.
var _object_placer_instance: ObjectPlacer


func _ready():
	_generate_level()

# Main generation function that orchestrates the entire process.
func _generate_level():
	# --- 1. Initialization ---
	_initialize_generation_state()
	
	# Pack all parameters into a dictionary to easily pass them to static methods.
	# This dictionary does NOT include rooms/corridors yet, as they haven't been generated.
	var generation_params = {
		"level_size": level_size,
		"room_count": room_count,
		"min_room_size": min_room_size,
		"max_room_size": max_room_size,
		"prefab_chance": prefab_chance,
		"prefab_defs": prefab_defs,
		"item_defs": item_defs,
		"poi_defs": poi_defs,
		"floor_scene": floor_scene,
		"wall_scene": wall_scene,
		"void_cube_scene": void_cube_scene,
		"rng": _rng,
		"grid": _grid
	}
	
	# --- 2. Logical Generation Phases ---
	# These phases create the logical map in the _grid data structure.
	_rooms = RoomGenerator.generate_rooms(_grid, generation_params)
	_corridors = CorridorGenerator.generate_corridors(_grid, _rooms, level_size)
	TileAnalyzer.analyze_tiles(_grid, _rooms, _corridors, level_size)
	
	# --- 3. Physical Placement Phase ---
	# BUG FIX: Update the dictionary with the newly generated data BEFORE passing it to the placer.
	generation_params["rooms"] = _rooms
	generation_params["corridors"] = _corridors
	_object_placer_instance.place_all_objects(self, generation_params)
	
	# Optional: For debugging the logical room layout.
	# _debug_draw_rooms()


# Sets up or resets all the state variables for a new level generation.
func _initialize_generation_state():
	# Clear any previously generated objects from the scene.
	for child in get_children():
		child.queue_free()
		
	# Initialize the Random Number Generator.
	_rng = RandomNumberGenerator.new()
	if rn_seed != 0:
		_rng.seed = rn_seed
	else:
		_rng.randomize()

	# Initialize the data structures.
	_grid.clear()
	for x in range(level_size.x):
		_grid.append([])
		for y in range(level_size.y):
			_grid[x].append(LevelTileData.new())
	
	_rooms.clear()
	_corridors.clear()
	
	# Create an instance of the placer since its methods are not static.
	_object_placer_instance = ObjectPlacer.new()


# Draws semi-transparent boxes to visualize the logical room rectangles for debugging.
func _debug_draw_rooms():
	for room in _rooms:
		var mesh_inst = MeshInstance3D.new()
		var box = BoxMesh.new()
		
		var world_w = room.rect.size.x * 4.0
		var world_h = room.rect.size.y * 4.0
		box.size = Vector3(world_w, 4.0, world_h)
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(1, 0, 0, 0.3)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		box.material = mat
		
		mesh_inst.mesh = box
		add_child(mesh_inst)
		
		var center_x = (room.rect.position.x * 4.0) + (world_w / 2.0)
		var center_z = (room.rect.position.y * 4.0) + (world_h / 2.0)
		mesh_inst.position = Vector3(center_x, 2.0, center_z)
