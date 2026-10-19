extends Node

# --- Estado del juego ---
var current_station: Station = null

## Referencia al nodo Main (asignada por main.gd en _ready).
var main: Control = null

## Ruta del recurso de equilibrio de partida. Se carga por ruta (no preload)
## para evitar ciclos de importación y permitir editar el .tres sin recompilar.
const BALANCE_PATH: String = "res://resources/config/balance_default.tres"

## Datos de equilibrio de la partida (dinero, renta, jornada, cupos, clientes).
## Si el recurso falta, se usan las constantes de respaldo del archivo.
var balance: RunBalance = null

## Almacén persistente de ingredientes preparados (Sección 2 -> Sección 3).
var warehouse: AlmacenPreparados = null

## Materia prima de la Sección 2, con cupo diario configurado desde `balance`.
var materia_prima: Inventario = null


func _ready() -> void:
	balance = load(BALANCE_PATH) as RunBalance
	warehouse = AlmacenPreparados.new()
	warehouse.name = "AlmacenPreparados"
	add_child(warehouse)
	materia_prima = Inventario.new()
	materia_prima.name = "MateriaPrima"
	add_child(materia_prima)
	if balance != null:
		for limite in balance.stock_limits:
			if limite != null:
				materia_prima.configurar_limite(limite.item, limite.daily_limit)


# =========================================================
# DINERO
# =========================================================

## Respaldo si `balance` no carga. El valor real sale de RunBalance.
const STARTING_MONEY: int = 20
## Respaldo de la renta de fin de día (ver RunBalance.rent_cost).
const RENT_COST: int = 15

## Saldo actual. Escucha money_changed para actualizar UI.
var money: int = STARTING_MONEY

## Ganancias acumuladas del día en curso (pagos de clientes).
var day_earnings: int = 0

## Resumen de la última liquidación de día (ver end_day()).
var last_settlement: Dictionary = {}

## Emitida cada vez que el saldo cambia. La UI debe conectarse a esta señal.
signal money_changed(new_amount: int)

## Emitida al liquidar el día con (ganancias del día, renta cobrada, saldo).
## La UI de fin de día la usa para mostrar el resumen.
signal day_settled(earnings: int, rent: int, balance: int)


## Suma dinero al saldo (pagos de clientes) y lo cuenta como ganancia del día.
func add_money(amount: int) -> void:
	money += amount
	day_earnings += amount
	money_changed.emit(money)

## Resta dinero del saldo. Devuelve true si había fondos suficientes.
func spend_money(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	money_changed.emit(money)
	return true

## Reinicia el saldo al valor inicial y limpia las ganancias del día.
func reset_money() -> void:
	money = _starting_money()
	day_earnings = 0
	money_changed.emit(money)

func _starting_money() -> int:
	return balance.starting_money if balance != null else STARTING_MONEY

func _rent_cost() -> int:
	return balance.rent_cost if balance != null else RENT_COST

func _day_duration() -> float:
	return balance.day_duration if balance != null else DAY_DURATION


# =========================================================
# DÍA / JORNADA
# =========================================================

## Emitida cuando el temporizador del día llega a cero.
signal day_ended()
## Emitida cada segundo con los segundos restantes del día.
signal day_tick(seconds_remaining: float)

## Respaldo de la duración del día (ver RunBalance.day_duration).
const DAY_DURATION: float = 2.0 * 60.0

var _day_timer: Timer = null
var _day_elapsed: float = 0.0
var day_running: bool = false

## Arranca el temporizador del día y repone los cupos diarios.
## Con `deferred = true` inicializa el estado pero NO arranca el timer ni el
## conteo; usa `resume_day()` después (ej. al cerrar el banner de objetivo).
func start_day(deferred: bool = false) -> void:
	reset_money()
	if warehouse != null:
		warehouse.reset()
	if materia_prima != null:
		materia_prima.reset_dia()
	_day_elapsed = 0.0
	day_running = false   # se activa en resume_day()

	if _day_timer == null:
		_day_timer = Timer.new()
		_day_timer.one_shot = true
		_day_timer.timeout.connect(_on_day_timer_timeout)
		add_child(_day_timer)

	if not deferred:
		day_running = true
		_day_timer.start(_day_duration())

## Para el temporizador (sin resetear el tiempo transcurrido).
func stop_day() -> void:
	day_running = false
	if is_instance_valid(_day_timer):
		_day_timer.stop()

## Liquida el día: cobra la renta (puede dejar saldo negativo = deuda) y
## publica el resumen en `last_settlement`. Devuelve ese mismo resumen.
## Lo llama `main.gd` al recibir `day_ended`.
func end_day() -> Dictionary:
	stop_day()
	var rent := _rent_cost()
	var debt := maxi(rent - money, 0)
	money -= rent
	money_changed.emit(money)
	last_settlement = {
		"earnings": day_earnings,
		"rent": rent,
		"balance": money,
		"debt": debt,
	}
	day_settled.emit(day_earnings, rent, money)
	return last_settlement

## Reanuda el temporizador desde donde quedó (usado al salir de pausa).
## No resetea dinero ni _day_elapsed.
func resume_day() -> void:
	if _day_timer == null:
		return
	var remaining := maxf(_day_duration() - _day_elapsed, 0.0)
	if remaining <= 0.0:
		return
	day_running = true
	_day_timer.start(remaining)

func _process(delta: float) -> void:
	if not day_running:
		return
	_day_elapsed += delta
	var remaining := maxf(_day_duration() - _day_elapsed, 0.0)
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
		AudioManager.play_music(AudioManager.MUSIC.MAIN_THEME)


# =========================================================
# LÓGICA DE LAS 4 ESTACIONES
# =========================================================

enum Side { FRONT, LEFT, RIGHT, BACK }
enum Turn { LEFT, RIGHT, BACK }

## Emitida cuando cambia la estación visible. El HUD la usa para mostrar la
## información de la sección correspondiente (precios, crudos, preparados).
signal station_changed(side: int)

const SideOrder: Array = [Side.FRONT, Side.LEFT, Side.BACK, Side.RIGHT]

var _stations: Dictionary = {}   # Side → Station
var _current_side: int = Side.FRONT

@export var slide_duration: float = 0.35
var _is_animating: bool = false

func setup_stations(stations: Dictionary) -> void:
	_stations = stations
	show_side(Side.FRONT)

## Estación visible actual (un valor de `Side`).
func current_side() -> int:
	return _current_side

## Devuelve la estación registrada para un `Side` (o null si no existe).
## Usado por nodos que operan entre secciones, p. ej. DispatchZone.
func get_station(side: int) -> Station:
	return _stations.get(side, null)

func show_side(side: int) -> void:
	for s in _stations.values():
		if is_instance_valid(s):
			s.hide()
			s.position = Vector2.ZERO
			_set_interaction_enabled(s, false)

	var target: Station = _stations.get(side, null)
	if is_instance_valid(target):
		target.show()
		target.position = Vector2.ZERO
		_set_interaction_enabled(target, true)

	_current_side = side
	current_station = target
	station_changed.emit(side)

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
	if _is_animating:
		return

	var index: int = SideOrder.find(_current_side)
	if index == -1:
		return

	var next_index: int = index
	match direction:
		Turn.LEFT:  next_index = (index + 1) % SideOrder.size()
		Turn.RIGHT: next_index = (index - 1 + SideOrder.size()) % SideOrder.size()
		Turn.BACK:  next_index = (index + 2) % SideOrder.size()

	var next_side: int = SideOrder[next_index]
	var current_st: Station = _stations.get(_current_side, null)
	var next_st: Station = _stations.get(next_side, null)

	if not is_instance_valid(next_st) or current_st == next_st:
		return

	_is_animating = true

	if is_instance_valid(current_st):
		_set_interaction_enabled(current_st, false)
	_set_interaction_enabled(next_st, false)

	var viewport_width: float = get_viewport().get_visible_rect().size.x

	var dir_multiplier: float = 1.0 if direction == Turn.LEFT else -1.0
	if direction == Turn.BACK:
		dir_multiplier = 1.0

	var start_pos_next := Vector2(viewport_width * -dir_multiplier, 0.0)
	var end_pos_current := Vector2(viewport_width * dir_multiplier, 0.0)

	next_st.position = start_pos_next
	next_st.show()

	var tween := create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)

	if is_instance_valid(current_st):
		tween.tween_property(current_st, "position", end_pos_current, slide_duration)
	tween.tween_property(next_st, "position", Vector2.ZERO, slide_duration)

	await tween.finished

	if is_instance_valid(current_st):
		current_st.hide()
		current_st.position = Vector2.ZERO

	_set_interaction_enabled(next_st, true)
	_current_side = next_side
	current_station = next_st
	station_changed.emit(next_side)
	_is_animating = false


func refill_ing(item: ItemData, cantidad: int) -> void:
	if materia_prima == null or item == null or cantidad < 0:
		return

	var diferencia := cantidad - materia_prima.cantidad_de(item)
	if diferencia > 0:
		materia_prima.agregar(item, diferencia)
