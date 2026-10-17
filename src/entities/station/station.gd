extends Node2D
class_name Station

@export var right_station : PackedScene
@export var left_station : PackedScene
@export var dowm_station : PackedScene

func _on_buttom_area_entered(_area: Area2D) -> void:
	GameManager.load_scene(dowm_station)


func _on_right_area_entered(_area: Area2D) -> void:
	GameManager.load_scene(right_station)

func _on_left_area_entered(_area: Area2D) -> void:
	GameManager.load_scene(left_station)
