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

## Devuelve la estación registrada para un `Side` (o null si no existe).
## Usado por nodos que operan entre secciones, p. ej. DispatchZone.
func get_station(side: int) -> Station:
	return _stations.get(side, null)

func show_side(side: int) -> void:
	for s in _stations.values():
		if is_instance_valid(s):
			s.hide()
			_set_interaction_enabled(s, false)

	var target: Station = _stations.get(side, null)
	if is_instance_valid(target):
		target.show()
		_set_interaction_enabled(target, true)

	_current_side = side
	current_station = target

## Habilita o deshabilita la detección física de las áreas de una estación.
## `hide()` sólo oculta el dibujo: sin esto, los Area2D de las estaciones
## ocultas seguirían detectando drops del jugador en las mismas coordenadas
## (todas las estaciones comparten el espacio de la escena).
func _set_interaction_enabled(node: Node, enabled: bool) -> void:
	if node is Area2D:
		node.set_deferred("monitoring", enabled)
		node.set_deferred("monitorable", enabled)
	for child in node.get_children():
		_set_interaction_enabled(child, enabled)

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
