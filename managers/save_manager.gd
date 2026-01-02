extends Node

const PLAYER_PATH = "user://player.tres"

## Optimization technique, to reload
var _has_data_changed: bool = true
var _player_data_cache: PlayerSaveData

## Loads and set data to the player.
func set_data_to_player(player: Player) -> void:
	var data = load_player()
	if not is_instance_valid(data):
		GlobalLogger.info("set_data_to_player: No saved data; returning...")
		return
	
	# Weapon Component
	player.weapon_component.bullet_left = data.bullet_left
	player.weapon_component.bullet_right = data.bullet_right
	
	if data.throwable_left:
		player.weapon_component.throwable_left_count = 2
		player.weapon_component.throwable_left = data.throwable_left
	if data.throwable_right:
		player.weapon_component.throwable_right_count = 2
		player.weapon_component.throwable_right = data.throwable_right
	
	player.weapon_component.assistant = data.assistant
	
	# Movement Component
	player.movement_component.propulsor = data.propulsor

	# Health Component
	player.health_component.core = data.core
	player.health_component.current_health = data.core.health

	# Leveling System
	player.leveling_system.current_level = data.player_level
	player.leveling_system.current_xp = data.current_xp
	player.leveling_system.prev_level_up_xp = data.prev_level_up_xp
	player.leveling_system.next_level_up_xp = data.next_level_up_xp

	# Game Stats
	#@export var total_dies: int
	#@export var total_kills: int

## Returns data extracted from a player
func get_data_from_player(player: Player) -> PlayerSaveData:
	var data = PlayerSaveData.new()
	# Weapon Component
	data.bullet_left = player.weapon_component.bullet_left
	data.bullet_right = player.weapon_component.bullet_right
	data.throwable_left = player.weapon_component.throwable_left
	data.throwable_right = player.weapon_component.throwable_right
	data.assistant = player.weapon_component.assistant
	
	# Movement Component
	data.propulsor = player.movement_component.propulsor

	# Health Component
	data.core = player.health_component.core

	# Leveling System
	data.player_level = player.leveling_system.current_level
	data.current_xp = player.leveling_system.current_xp
	data.prev_level_up_xp = player.leveling_system.prev_level_up_xp
	data.next_level_up_xp = player.leveling_system.next_level_up_xp

	# Game Stats
	#@export var total_dies: int
	#@export var total_kills: int

	return data

func save_player(data: PlayerSaveData):
	var err = ResourceSaver.save(data, PLAYER_PATH)
	GlobalLogger.info("SaveManager.save_player: ", err)
	_has_data_changed = true

func load_player() -> PlayerSaveData:
	if not _has_data_changed:
		return _player_data_cache
	
	if ResourceLoader.exists(PLAYER_PATH):
		var data = ResourceLoader.load(PLAYER_PATH).duplicate(true)
		_player_data_cache = data
		_has_data_changed = false
		return data as PlayerSaveData
	else:
		return null
