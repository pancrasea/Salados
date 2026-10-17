extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Boton de jugar
	$VBoxContainer/Buttons/HBoxContainer/Button.text = "Jugar"
	$VBoxContainer/Buttons/HBoxContainer/Button.pressed.connect(_on_button_pressed.bind("Jugar"))
	#Boton de Opciones 
	$VBoxContainer/Buttons2/HBoxContainer/Button.text = "Opciones"
	$VBoxContainer/Buttons2/HBoxContainer/Button.pressed.connect(_on_button_pressed.bind("Opciones"))
	#Boton de Salir
	$VBoxContainer/Buttons3/HBoxContainer/Button.text = "Salir"
	$VBoxContainer/Buttons3/HBoxContainer/Button.pressed.connect(_on_button_pressed.bind("Salir"))

#Acciones de cada boton
func _on_button_pressed(accion):
	match accion:
		"Jugar":
			get_tree().change_scene_to_file("res://src/entities/station/Station.tscn") #lleva ala main scena
		"Opciones":
			get_tree().change_scene_to_file("res://src/entities/station/Station.tscn") #lleva la menu de opciones
		"Salir":
			get_tree().quit() # cierra el juego
	



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
