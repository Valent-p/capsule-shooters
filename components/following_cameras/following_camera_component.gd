extends Node3D


@export var agent: Node3D

func _ready() -> void:
	assert(agent != null, "FollowingCameraComponent: agent is required!")
