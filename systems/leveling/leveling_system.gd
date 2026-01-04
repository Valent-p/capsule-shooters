extends Node
class_name LevelingSystem

const progress_factor: float = 1.35

@export var current_level: int = 1

@export var next_level_up_xp: int = 100
var prev_level_up_xp: int = 0

@export var current_xp: int = 1

@export var agent: Character
## Must have "level" member and must handle freeing itself
@export var level_up_effect_scene: PackedScene 

signal leveled_up(current_level: int, current_xp: int, prev_level_up_xp:int, next_level_up_xp: int)
signal xp_changed(current_xp: int, current_level, prev_level_up_xp:int, next_level_up_xp: int)


func _ready() -> void:
	assert(agent != null, "LevelingSystem: agent is required!")
	assert(level_up_effect_scene != null, "LevelingSystem: level_up_effect_scene is required!")
	## Load saved data, if we have a saved file
	var player_data = SaveManager.load_player()
	if player_data:
		current_xp = player_data.current_xp
		current_level = player_data.player_level
		prev_level_up_xp = player_data.prev_level_up_xp
		next_level_up_xp = player_data.next_level_up_xp

func add_xp(xp: int) -> void:
	current_xp += xp
	xp_changed.emit(current_xp, current_level, prev_level_up_xp, next_level_up_xp)
	
	if current_xp >= next_level_up_xp:
		prev_level_up_xp = next_level_up_xp
		next_level_up_xp += int((current_level ** progress_factor) * 100.0)
		current_level += 1
		leveled_up.emit(current_level, current_xp, prev_level_up_xp, next_level_up_xp)
		GlobalLogger.info("LevelUP: level: ", current_level, " xp: ", current_xp,"prev: ", prev_level_up_xp, " next_xp: ", next_level_up_xp)

func _on_leveled_up(new_level: int, _current_xp: int, _prev_level_up_xp:int, _next_level_up_xp: int) -> void:
	var vfx = level_up_effect_scene.instantiate()
	vfx.level = new_level
	agent.add_child(vfx)
	
