extends Control

## Menú de pausa. Vive como hijo de un CanvasLayer en main.tscn con
## process_mode = ALWAYS para capturar input aunque el árbol esté pausado.
## Se activa con Escape (ui_cancel) y llama a main.gd para pausar/reanudar
## el timer del día junto con get_tree().paused.


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
	# Detener el contador del día mientras está pausado.
	if is_instance_valid(GameManager.main):
		GameManager.main.on_game_paused()
	%ContinueButton.grab_focus()

func _resume_game() -> void:
	get_tree().paused = false
	hide()
	# Reanudar el contador del día.
	if is_instance_valid(GameManager.main):
		GameManager.main.on_game_resumed()


func _on_continue_button_pressed() -> void:
	_resume_game()

func _on_home_button_pressed() -> void:
	get_tree().paused = false
	hide()
	GameManager.go_to_menu()
	

func _on_option_button_pressed() -> void:
	%OptionButton.disabled = true
	$Panel/VBoxContainer/Label.text = "Opciones no disponibles"
