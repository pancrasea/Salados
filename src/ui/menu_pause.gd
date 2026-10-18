extends Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			_resume_game()
		else:
			_pause_game()
		get_viewport().set_input_as_handled()


func _pause_game() -> void:
	show()
	get_tree().paused = true
	$Panel/VBoxContainer2/Button.grab_focus()


func _resume_game() -> void:
	get_tree().paused = false
	hide()


func _on_button_3_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://src/ui/MainMenu.tscn")


func _on_button_2_pressed() -> void:
	$Panel/VBoxContainer2/Button2.disabled = true
	$Panel/VBoxContainer/Label.text = "Opciones no disponibles"


func _on_button_pressed() -> void:
	_resume_game()
