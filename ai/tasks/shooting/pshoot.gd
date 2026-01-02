@tool
extends BTAction
## Pshoot

@export var target_var: StringName = &"target"
@export var distance_range: float = 15.0

# Display a customized name (requires @tool).
func _generate_name() -> String:
	return "PShoot %s until out of range %d" % [LimboUtility.decorate_var(target_var), distance_range]


# Called once during initialization.
func _setup() -> void:
	pass


# Called each time this task is entered.
func _enter() -> void:
	pass


# Called each time this task is exited.
func _exit() -> void:
	pass


# Called each time this task is ticked (aka executed).
func _tick(_delta: float) -> Status:
	if not is_instance_valid(blackboard.get_var(target_var)): return FAILURE
	
	var target: Node3D = blackboard.get_var(target_var)
	var target_pos = target.global_position
	
	var distance = agent.global_position.distance_to(target_pos)
	if distance >= distance_range or ((agent.sight_check_raycast as RayCast3D).is_colliding() and (agent.sight_check_raycast as RayCast3D).get_collider() is not Player):
		return FAILURE
	
	var dir =  agent.global_position.direction_to(target_pos)
	agent.rotation.y = deg_to_rad(180) + atan2(dir.x, dir.z)
	agent.weapon_component.shoot(true)
	
	return RUNNING


# Strings returned from this method are displayed as warnings in the behavior tree editor (requires @tool).
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	return warnings
