extends Node3D

@export var health_component: HealthComponent

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Label3D.text = str(health_component.current_health) + "/" + str(health_component.core.health)
	health_component.health_changed.connect(_on_health_changed)

func _on_health_changed(current_health: float, max_health: float):
	$Label3D.text = str(health_component.current_health) + "/" + str(health_component.core.health)
