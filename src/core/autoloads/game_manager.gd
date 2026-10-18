extends Node

# --- Estado del juego ---
var current_station: Station = null

# Referencia al nodo Main (asignada por main.gd en _ready)
var main: Control = null


# --- Cambio de pantallas ---

func go_to_game() -> void:
	if is_instance_valid(main):
		main.start_game()

func go_to_menu() -> void:
	if is_instance_valid(main):
		main.return_to_menu()


# --- Lógica de las 4 estaciones (antes en Level) ---

enum Side { FRONT, LEFT, RIGHT, BACK }
enum Turn { LEFT, RIGHT, BACK }

const SideOrder: Array = [Side.FRONT, Side.LEFT, Side.BACK, Side.RIGHT]

var _stations: Dictionary = {}   # Side → Station
var _current_side: int = Side.FRONT

func setup_stations(stations: Dictionary) -> void:
	_stations = stations
	show_side(Side.FRONT)

func show_side(side: int) -> void:
	for s in _stations.values():
		if is_instance_valid(s):
			s.hide()

	var target: Station = _stations.get(side, null)
	if is_instance_valid(target):
		target.show()

	_current_side = side
	current_station = target

func turn_left() -> void:
	_turn(Turn.LEFT)

func turn_right() -> void:
	_turn(Turn.RIGHT)

func turn_back() -> void:
	_turn(Turn.BACK)

func _turn(direction: int) -> void:
	var index: int = SideOrder.find(_current_side)
	if index == -1:
		return
	match direction:
		Turn.LEFT:  index = (index + 1) % SideOrder.size()
		Turn.RIGHT: index = (index - 1 + SideOrder.size()) % SideOrder.size()
		Turn.BACK:  index = (index + 2) % SideOrder.size()
	show_side(SideOrder[index])
