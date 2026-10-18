extends Control

@onready var jugar_btn: TextureButton = $VBoxContainer/ButtonWidget/HBoxContainer/TextureButton
@onready var settings_btn: TextureButton = $VBoxContainer/ButtonWidget2/HBoxContainer/TextureButton
@onready var galeria_btn: TextureButton = $VBoxContainer/ButtonWidget3/HBoxContainer/TextureButton
@onready var salir_btn: TextureButton = $VBoxContainer/ButtonWidget4/HBoxContainer/TextureButton

func _ready() -> void:
	jugar_btn.pressed.connect(_play)
	settings_btn.pressed.connect(_open_settings)
	galeria_btn.pressed.connect(_open_gallery)
	salir_btn.pressed.connect(_exit)

func _play() -> void:
	GameManager.go_to_game()

func _open_settings() -> void:
	pass

func _open_gallery() -> void:
	pass

func _exit() -> void:
	get_tree().quit()
