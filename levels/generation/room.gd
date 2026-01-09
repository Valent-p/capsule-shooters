# /levels/generation/room.gd
# Defines a room or a prefab area in the level.
class_name Room
extends Object

var id: int
var rect: Rect2i
var prefab_scene: PackedScene = null
var density_modifier: float = 1.0
var distance_from_spawn: int = -1
var rotation_dir: PrefabItemData.Direction = PrefabItemData.Direction.NORTH

# Entrances stored in global grid coordinates.
var global_entrances: Array[Vector2i] = []

func _init(_id: int, _rect: Rect2i, _prefab_scene: PackedScene = null, _rot: PrefabItemData.Direction = PrefabItemData.Direction.NORTH):
	self.id = _id
	self.rect = _rect
	self.prefab_scene = _prefab_scene
	self.rotation_dir = _rot

# Finds the best entrance point on this room to connect to a target point.
# This is used by the corridor generator to create more direct paths.
func get_connection_point(target_center: Vector2) -> Vector2i:
	# For procedural rooms, the center is the only connection point.
	if prefab_scene == null:
		return rect.get_center()
	
	# If a prefab has no defined entrances, fall back to the center.
	if global_entrances.is_empty():
		return rect.get_center()
		
	# Find the entrance on this room that is closest to the target.
	var best_point = global_entrances[0]
	var min_dist = Vector2(best_point).distance_squared_to(target_center)
	for point in global_entrances:
		var d = Vector2(point).distance_squared_to(target_center)
		if d < min_dist:
			min_dist = d
			best_point = point
	return best_point
