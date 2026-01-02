@tool
extends BTCondition
## IsTargetInRange


@export var target_var: StringName = &"target"
@export var distance_range: float = 10.0

# Display a customized name (requires @tool).
func _generate_name() -> String:
	return "Is %s in range %d ?" % [LimboUtility.decorate_var(target_var), distance_range]


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
	
	var target_pos = blackboard.get_var(target_var).global_position
	var dist = agent.global_position.distance_to(target_pos)
	
	if dist <= distance_range:
		return SUCCESS
	else:
		return FAILURE


# Strings returned from this method are displayed as warnings in the behavior tree editor (requires @tool).
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	return warnings
