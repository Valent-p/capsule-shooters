extends Control

var result: String
signal done

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%ScreenLabel.text = ""

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _clicked(num: String):
	if len(%ScreenLabel.text) < 6:
		%ScreenLabel.text += num

func _on_button_01_pressed() -> void:
	_clicked("1")


func _on_button_02_pressed() -> void:
	_clicked("2")


func _on_button_03_pressed() -> void:
	_clicked("3")


func _on_button_04_pressed() -> void:
	_clicked("4")


func _on_button_05_pressed() -> void:
	_clicked("5")


func _on_button_06_pressed() -> void:
	_clicked("6")


func _on_button_07_pressed() -> void:
	_clicked("7")


func _on_button_08_pressed() -> void:
	_clicked("8")


func _on_button_09_pressed() -> void:
	_clicked("9")


func _on_button_00_pressed() -> void:
	_clicked("0")

func _on_button_d_pressed() -> void:
	%ScreenLabel.text = %ScreenLabel.text.substr(0, len(%ScreenLabel.text)-1)


func _on_button_e_pressed() -> void:
	result = %ScreenLabel.text
	done.emit()
	
