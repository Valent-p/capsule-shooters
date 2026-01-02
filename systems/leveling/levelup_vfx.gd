extends Node3D

## Parameters
var level: int

@export var label_scale_curve: Curve


func _ready() -> void:
	$GPUParticles3D.emitting = true

func _on_gpu_particles_3d_finished() -> void:
	queue_free()
	
