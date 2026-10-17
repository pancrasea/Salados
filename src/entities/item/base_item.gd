class_name BaseItem extends Node2D

@export var data: ItemData

var is_dragging: bool = false

@onready var sprite_2d: Sprite2D = $Sprite2D


func _ready() -> void:
	if data:
		_update_data()

func _update_data():
	if sprite_2d:
		if data:
			sprite_2d.texture = data.icon
		else:
			sprite_2d.texture = null

func _process(delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position()

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			is_dragging = true
		else:
			is_dragging = false
			# TODO: Comprobar si esta en una estacion de trabajo
