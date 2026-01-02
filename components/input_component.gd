extends Node
class_name InputComponent
## Player Input component for movement, shooting, aiming, ...

@export var movement_component: MovementComponent
@export var weapon_component: WeaponComponent
@export var agent: CharacterBody3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	movement_component.direction = agent.global_transform.basis * Vector3(dir.x, 0, dir.y)
	
	if Input.is_action_pressed("shoot_left"):
		weapon_component.shoot(false)
	if Input.is_action_pressed("shoot_right"):
		weapon_component.shoot(true)
	if Input.is_action_just_pressed("throw_left"):
		weapon_component.throw(false)
	if Input.is_action_just_pressed("throw_right"):
		weapon_component.throw(true)
	
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		event = event as InputEventMouse
		agent.rotate_y(-event.relative.x * 0.005)
