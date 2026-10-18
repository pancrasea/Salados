extends Control

# Referencia al CanvasLayer que contiene la pantalla activa
@onready var scene_layer: CanvasLayer = $SceneLayer

# Escenas disponibles para cargar
const MAIN_MENU_SCENE = preload("res://src/ui/MainMenu.tscn")
const TESTING_LEVEL_SCENE = preload("res://src/levels/TestingLevel.tscn")

func _ready() -> void:
	# Registrar Main en GameManager para que pueda pedir cambios de pantalla
	GameManager.main = self
	# Empezar en el menú principal
	change_screen(MAIN_MENU_SCENE)


# Limpia SceneLayer y carga la nueva pantalla como hijo
func change_screen(scene: PackedScene) -> void:
	# Eliminar la pantalla actual si existe
	for child in scene_layer.get_children():
		child.queue_free()

	var instance := scene.instantiate()
	scene_layer.add_child(instance)
