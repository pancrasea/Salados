extends Node2D
class_name Level

enum Side { FRONT, LEFT, RIGHT, BACK }
enum Turn { LEFT, RIGHT, BACK }

const SideOrder = [
	Side.FRONT,
	Side.LEFT,
	Side.BACK,
	Side.RIGHT
]


#luego cambiar por cada scena de las 4 estaciones
var main_station_scene: PackedScene = preload("res://src/entities/station/MainStation.tscn")
var left_station_scene: PackedScene = preload("res://src/entities/station/BackStation.tscn")
var right_station_scene: PackedScene = preload("res://src/entities/station/BackStation.tscn")
var back_station_scene: PackedScene = preload("res://src/entities/station/BackStation.tscn")

var main_station: Station
var left_station: Station
var right_station: Station
var back_station: Station

var current_side = Side.FRONT
var current_station: Station = null

func _ready() -> void:
	GameManager.current_level = self

	main_station = _create_station(main_station_scene)
	left_station = _create_station(left_station_scene)
	right_station = _create_station(right_station_scene)
	back_station = _create_station(back_station_scene)

	show_side(Side.FRONT)

func _create_station(scene: PackedScene) -> Station:
	if scene == null: return null
	var node := scene.instantiate()

	if not node is Station:
		node.free()
		return null

	var station : Station = node as Station
	station.hide()
	add_child(station)

	return station

func show_side(side: int) -> void:
	var target: Station

	match side:
		Side.FRONT:
			target = main_station
		Side.LEFT:
			target = left_station
		Side.RIGHT:
			target = right_station
		Side.BACK:
			target = back_station

	if not is_instance_valid(target): return
	for station in [main_station, left_station, right_station, back_station]:
		if is_instance_valid(station):
			station.hide()

	target.show()

	current_side = side
	current_station = target
	GameManager.current_station = target


func turn_view(direction: int) -> void:
	var index: int = SideOrder.find(current_side)
	if index == -1: return

	match direction:
		Turn.LEFT: index = (index + 1) % SideOrder.size()
		Turn.RIGHT: index = (index - 1 + SideOrder.size()) % SideOrder.size()
		Turn.BACK: index = (index + 2) % SideOrder.size()

	show_side(SideOrder[index])
