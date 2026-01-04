extends Control

func _ready() -> void:
	assert($CenterContainer != null, "GameOverUI: $CenterContainer is required!")
	$CenterContainer.scale = Vector2(.2, .2)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if $CenterContainer.scale.x < 1:
		$CenterContainer.pivot_offset = size/2
		$CenterContainer.scale += Vector2.ONE * delta * 2
