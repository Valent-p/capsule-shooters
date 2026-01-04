extends Node3D

## Parameters
var level: int

@export var label_scale_curve: Curve



func _ready() -> void:
	assert(label_scale_curve != null, "LevelUpVFX: label_scale_curve is required!")
	$GPUParticles3D.emitting = true

func _on_gpu_particles_3d_finished() -> void:
	queue_free()
	
