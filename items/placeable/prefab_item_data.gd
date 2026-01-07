class_name PrefabItemData
extends Resource

enum Direction { NORTH, EAST, SOUTH, WEST }

@export var prefab_scene: PackedScene
@export var width: int = 5
@export var height: int = 5
@export var entrances: Array[Vector2i]

@export_group("Orientation")
@export var randomize_rotation: bool = false
@export var fixed_direction: Direction = Direction.NORTH
