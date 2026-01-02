extends GPUParticles3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	emitting = true
	$RemoveTimer.wait_time = self.lifetime
	$RemoveTimer.timeout.connect(queue_free)

func _on_finished() -> void:
	queue_free()
