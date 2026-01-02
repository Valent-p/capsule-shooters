extends Node
class_name MovementComponent

@export var propulsor: PropulsorItemData
@export var agent: CharacterBody3D
@export var speed: float = 8.0

## If direction is not Vector.ZERO, move
var direction: Vector3 = Vector3.ZERO

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	agent.velocity = direction * speed
	
	if not agent.is_on_floor():
		agent.velocity += agent.get_gravity()
	
	agent.move_and_slide()
	
	# Reset to avoid continuous movement
	direction = Vector3.ZERO
