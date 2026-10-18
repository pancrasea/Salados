extends Control


func _ready() -> void:
	# Botón de jugar
	$VBoxContainer/Buttons/HBoxContainer/Button.text = "Jugar"
	$VBoxContainer/Buttons/HBoxContainer/Button.pressed.connect(_on_button_pressed.bind("Jugar"))
	# Botón de Opciones
	$VBoxContainer/Buttons2/HBoxContainer/Button.text = "Opciones"
	$VBoxContainer/Buttons2/HBoxContainer/Button.pressed.connect(_on_button_pressed.bind("Opciones"))
	# Botón de Salir
	$VBoxContainer/Buttons3/HBoxContainer/Button.text = "Salir"
	$VBoxContainer/Buttons3/HBoxContainer/Button.pressed.connect(_on_button_pressed.bind("Salir"))


func _on_button_pressed(accion: String) -> void:
	match accion:
		"Jugar":
			GameManager.go_to_game()
		"Opciones":
			pass # TODO: cargar pantalla de opciones
		"Salir":
			get_tree().quit()
