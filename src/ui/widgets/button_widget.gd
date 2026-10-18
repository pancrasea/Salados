extends Control

@onready var icono : TextureRect = $HBoxContainer/TextureRect
@onready var boton : TextureButton = $HBoxContainer/TextureButton

func _ready() -> void:
	icono.modulate.a = 0.0

func _on_button_mouse_exited() -> void:
	icono.modulate.a = 0.0

func _on_button_mouse_entered() -> void:
	icono.modulate.a = 1.0
