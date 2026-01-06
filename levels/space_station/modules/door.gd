extends Node3D

@export var locked: bool = false

var initial_door_pos: Vector3
var duration: float = 1.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initial_door_pos = $"wall_thin-middle_door/Door".position
	update_indicator()

func update_indicator():
	if locked:
		var emission: BaseMaterial3D = ($"wall_thin-middle_door/Base".mesh as Mesh).surface_get_material(2).duplicate_deep()
		emission.emission = Color.RED
		var mesh: Mesh = ($"wall_thin-middle_door/Base".mesh as Mesh).duplicate()
		mesh.surface_set_material(2, emission)
		$"wall_thin-middle_door/Base".mesh = mesh

func _on_sensor_body_entered(_body: Node3D) -> void:
	var tween = create_tween()
	tween.tween_property($"wall_thin-middle_door/Door", "position", initial_door_pos+Vector3(0, 1.95, 0), duration)


func _on_sensor_body_exited(_body: Node3D) -> void:
	var tween = create_tween()
	tween.tween_property($"wall_thin-middle_door/Door", "position", initial_door_pos, duration)
