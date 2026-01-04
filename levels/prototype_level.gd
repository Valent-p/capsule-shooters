extends Node3D


@onready var enemy_scn: PackedScene = preload("res://chars/enemies/simple_shooter_enemy/simple_shooter_enemy.tscn") 
var remaining_spawns: int = 100

func _ready() -> void:
	assert(enemy_scn != null, "PrototypeLevel: enemy_scn is required!")
	assert($SpawnPoints != null, "PrototypeLevel: $SpawnPoints is required!")
	assert($SpawnPoints.get_child_count() > 0, "PrototypeLevel: $SpawnPoints must have at least one child!")

func _on_spawn_timer_timeout() -> void:
	if remaining_spawns <= 0: return 
	
	var enemy: Enemy = enemy_scn.instantiate()
	var pos = $SpawnPoints.get_children().pick_random().global_position
	enemy.position = pos
	add_child(enemy)
	remaining_spawns -= 1
	
