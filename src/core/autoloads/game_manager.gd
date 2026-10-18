extends Node

# --- Estado del juego ---
var current_station: Station = null

## Referencia al nodo Main (asignada por main.gd en _ready).
var main: Control = null


# =========================================================
# DINERO
# =========================================================

## Saldo inicial del jugador al empezar cada día.
const STARTING_MONEY: int = 20
## Renta de la carreta que se cobra al final del día.
const RENT_COST: int = 15

## Saldo actual. Escucha money_changed para actualizar UI.
var money: int = STARTING_MONEY

## Emitida cada vez que el saldo cambia. La UI debe conectarse a esta señal.
signal money_changed(new_amount: int)

## Suma dinero al saldo (pagos de clientes).
func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)

## Resta dinero del saldo. Devuelve true si había fondos suficientes.
func spend_money(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	money_changed.emit(money)
	return true

## Reinicia el saldo al valor inicial.
func reset_money() -> void:
	money = STARTING_MONEY
	money_changed.emit(money)


# =========================================================
# DÍA / JORNADA
# =========================================================

## Emitida cuando el temporizador del día llega a cero.
signal day_ended()
## Emitida cada segundo con los segundos restantes del día.
signal day_tick(seconds_remaining: float)

## Duración del día en segundos (2 minutos por defecto).
const DAY_DURATION: float = 2.0 * 60.0

var _day_timer: Timer = null
var _day_elapsed: float = 0.0
var day_running: bool = false

## Arranca el temporizador del día.
func start_day() -> void:
	reset_money()
	_day_elapsed = 0.0
	day_running = true

	if _day_timer == null:
		_day_timer = Timer.new()
		_day_timer.one_shot = true
		_day_timer.wait_time = DAY_DURATION
		_day_timer.timeout.connect(_on_day_timer_timeout)
		add_child(_day_timer)

	_day_timer.start(DAY_DURATION)

## Para el temporizador
func stop_day() -> void:
	day_running = false
	if is_instance_valid(_day_timer):
		_day_timer.stop()

func _process(delta: float) -> void:
	if not day_running:
		return
	_day_elapsed += delta
	var remaining := maxf(DAY_DURATION - _day_elapsed, 0.0)
	day_tick.emit(remaining)

func _on_day_timer_timeout() -> void:
	day_running = false
	day_ended.emit()


# =========================================================
# CAMBIO DE PANTALLAS
# =========================================================

func go_to_game() -> void:
	if is_instance_valid(main):
		main.start_game()

func go_to_menu() -> void:
	if is_instance_valid(main):
		main.return_to_menu()


# =========================================================
# LÓGICA DE LAS 4 ESTACIONES
# =========================================================

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
