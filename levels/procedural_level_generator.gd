class_name ProceduralLevelGenerator
extends Node3D

signal level_ready(level_data: Dictionary)

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
@export var placeable_defs: Array[PlaceableData] = []

@export_group("Scene Integration")
@export var nav_region: NavigationRegion3D

# --- Private Generation State ---
var _rng: RandomNumberGenerator
var _grid: Array = []
var _rooms: Array[Room] = []
var _corridors: Array[Vector2i] = []

var _object_placer_instance: ObjectPlacer

func _ready():
	# We no longer auto-generate. Wait for an external call to generate().
	pass

# Public method to be called by the level script to start generation.
func generate():
	_generate_level()

# Main generation function that orchestrates the entire process.
func _generate_level():
	# --- 1. Initialization ---
	_initialize_generation_state()
	
	var generation_params = {
		"level_size": level_size,
		"room_count": room_count,
		"min_room_size": min_room_size,
		"max_room_size": max_room_size,
		"prefab_chance": prefab_chance,
		"prefab_defs": prefab_defs,
		"placeable_defs": placeable_defs,
		"floor_scene": floor_scene,
		"wall_scene": wall_scene,
		"void_cube_scene": void_cube_scene,
		"rng": _rng,
		"grid": _grid
	}
	
	# --- 2. Logical Generation Phases ---
	_rooms = RoomGenerator.generate_rooms(_grid, generation_params)
	_corridors = CorridorGenerator.generate_corridors(_grid, _rooms, level_size)
	TileAnalyzer.analyze_tiles(_grid, _rooms, _corridors, level_size)
	
	# --- 3. Physical Placement Phase ---
	generation_params["rooms"] = _rooms
	generation_params["corridors"] = _corridors
	# IMPORTANT: We now pass the nav_region as the parent for all generated objects.
	_object_placer_instance.place_all_objects(nav_region, generation_params)
	
	# --- 4. Finalize and Emit Signal ---
	var final_level_data = {
		"rooms": _rooms,
		"corridors": _corridors,
		"grid": _grid
	}
	level_ready.emit(final_level_data)
	print("ProceduralLevelGenerator: Level generation complete. Emitting level_ready.")


# Sets up or resets all the state variables for a new level generation.
func _initialize_generation_state():
	# Clear any previously generated objects from the navigation region.
	if nav_region:
		for child in nav_region.get_children():
			child.queue_free()
	else:
		push_warning("NavigationRegion3D not set in ProceduralLevelGenerator. Objects will not be placed.")

	_rng = RandomNumberGenerator.new()
	if rn_seed != 0:
		_rng.seed = rn_seed
	else:
		_rng.randomize()

	_grid.clear()
	for x in range(level_size.x):
		_grid.append([])
		for y in range(level_size.y):
			_grid[x].append(LevelTileData.new())
	
	_rooms.clear()
	_corridors.clear()
	
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
