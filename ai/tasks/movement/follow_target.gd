@tool
extends BTAction
## FollowTarget

@export var target_var: StringName = &"target"
@export var arrive_range: float = 10.0
 
# Display a customized name (requires @tool).
func _generate_name() -> String:
	return "Follow %s until visible and at range %d" % [LimboUtility.decorate_var(target_var), arrive_range]


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
	
	var distance = agent.global_position.distance_to(target.global_position)
	if distance <= arrive_range and ((agent.sight_check_raycast as RayCast3D).is_colliding() and (agent.sight_check_raycast as RayCast3D).get_collider() is Player):
		return SUCCESS
	
	# Set target
	agent.nav_agent.target_position = target.global_position
	var next_path = (agent.nav_agent as NavigationAgent3D).get_next_path_position()
	var agent_pos = agent.global_position
	
	var dir: Vector3 = agent_pos.direction_to(next_path)
	agent.movement_component.direction = dir
	agent.rotation.y = deg_to_rad(180) + atan2(dir.x, dir.z)
	return SUCCESS


# Strings returned from this method are displayed as warnings in the behavior tree editor (requires @tool).
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	return warnings
