extends Node
## Manages everything in the game

@export var items_manager: ItemsManager
@export var main_menu_scene: PackedScene
@export var new_game_scene: PackedScene
@export var game_over_scene: PackedScene
@export var console_number_scene: PackedScene
@export var character_view_scene: PackedScene

var player: Player


func _ready() -> void:
	return
	assert(items_manager != null, "GameManager: items_manager is required!")
	assert(main_menu_scene != null, "GameManager: main_menu_scene is required!")
	assert(new_game_scene != null, "GameManager: new_game_scene is required!")
	assert(game_over_scene != null, "GameManager: game_over_scene is required!")
	assert(console_number_scene != null, "GameManager: console_number_scene is required!")
	assert(character_view_scene != null, "GameManager: character_view_scene is required!")
	## Try to load
	var loaded_player_save_data = SaveManager.load_player()
	## Loaded
	if loaded_player_save_data:
		GlobalLogger.info("GameManager: Loaded saved data.")
		## Show main menu
		to_main_menu()
	else:
		GlobalLogger.info("GameManager: No saved data; Starting new game.")
		start_new_game()

func to_main_menu():
	get_tree().change_scene_to_packed.call_deferred(main_menu_scene)

func start_new_game():
	get_tree().change_scene_to_packed.call_deferred(new_game_scene)

func open_character_view():
	get_tree().change_scene_to_packed.call_deferred(character_view_scene)

func animate_player_die():
	player.input_component.process_mode = Node.PROCESS_MODE_DISABLED

	var gameover = game_over_scene.instantiate()
	player.add_child(gameover)
	
	# Save the game:
	SaveManager.save_player(
		SaveManager.get_data_from_player(player)
	)
	
	## Slow motion
	var slow_mo_scale = .1
	Engine.time_scale = slow_mo_scale
	await get_tree().create_timer(3 * slow_mo_scale).timeout
	Engine.time_scale = 1
	
	start_new_game()

## Pauses the game, then request input from user by showing a console
func get_console_input_number(digits_count: int):
	var console = console_number_scene.instantiate()
	player.input_component.process_mode = Node.PROCESS_MODE_DISABLED
	player.add_child(console)
	await console.done
	return console.result
