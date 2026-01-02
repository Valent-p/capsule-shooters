extends Control

var current_right: Control
var current_button: Button

func _switch_rightside_to(button: Button, side: Control):
	if is_instance_valid(current_right): current_right.visible = false
	if is_instance_valid(current_button): current_button.button_pressed = false
	current_right = side
	current_right.visible = true
	current_button = button

func _on_quit_button_pressed() -> void:
	GlobalLogger.info("(MainMenu) cmd: Quit")
	get_tree().quit()


func _on_about_button_pressed() -> void:
	_switch_rightside_to(%AboutButton, %RightAbout)

func _on_options_button_pressed() -> void:
	_switch_rightside_to(%OptionsButton, %RightOptions)

func _on_load_game_button_pressed() -> void:
	_switch_rightside_to(%LoadGameButton, %RightLoadGame)

func _on_new_game_button_pressed() -> void:
	GameManager.start_new_game()

func _on_character_view_button_pressed() -> void:
	GameManager.open_character_view()
