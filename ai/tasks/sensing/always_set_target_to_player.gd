@tool
extends BTAction
## AlwaysSetTargetToPlayer

@export var target_var: StringName = &"target"

# Display a customized name (requires @tool).
func _generate_name() -> String:
	return "Always set target to player without condition"


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
	blackboard.set_var(target_var, agent.get_tree().get_first_node_in_group("Player"))
	return SUCCESS


# Strings returned from this method are displayed as warnings in the behavior tree editor (requires @tool).
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	return warnings
