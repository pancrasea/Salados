extends CanvasLayer

## Controles de navegación entre secciones. W/A/D/S, las flechas del teclado
## y las flechas de la UI abren la estación fija de cada dirección.
## La etiqueta indica la sección actual.

@onready var left: Control = $left
@onready var right: Control = $right
@onready var buttom: Control = $buttom
@onready var top: Control = $top
@onready var seccion_actual: Label = $SeccionActual

## Valores de GameManager.Side (FRONT, LEFT, RIGHT, BACK) repetidos como
## constantes locales para no depender del identificador global GameManager en
## arranques headless con `--script`.
const SIDE_FRONT: int = 0
const SIDE_LEFT: int = 1
const SIDE_RIGHT: int = 2
const SIDE_BACK: int = 3

## Autoload GameManager resuelto por ruta (ver hud.gd).
var _game_manager: Node = null


func _ready() -> void:
	_game_manager = get_node_or_null("/root/GameManager")
	if _game_manager == null:
		return
	var station_signal: Signal = _game_manager.get("station_changed")
	station_signal.connect(_on_station_changed)
	_on_station_changed(int(_game_manager.call("current_side")))


## Atajos activos solo mientras se juega; cada tecla apunta a una estación
## fija e ignora repeticiones al mantenerla pulsada.
func _input(event: InputEvent) -> void:
	if not visible or get_tree().paused:
		return
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	var target_side: int
	match key_event.keycode:
		KEY_W, KEY_UP:
			target_side = SIDE_FRONT
		KEY_A, KEY_LEFT:
			target_side = SIDE_LEFT
		KEY_D, KEY_RIGHT:
			target_side = SIDE_RIGHT
		KEY_S, KEY_DOWN:
			target_side = SIDE_BACK
		_:
			return
	_go_to_side(target_side)
	get_viewport().set_input_as_handled()


func _on_left_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_go_to_side(SIDE_LEFT)


func _on_right_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_go_to_side(SIDE_RIGHT)


func _on_buttom_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_go_to_side(SIDE_BACK)


func _on_top_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_go_to_side(SIDE_FRONT)


## Abre una estación fija mediante GameManager; lo comparten teclado y UI.
func _go_to_side(side: int) -> void:
	if _game_manager != null:
		_game_manager.call("turn_to_side", side)


func _on_station_changed(side: int) -> void:
	seccion_actual.text = "SECCIÓN: %s" % _side_name(side)


## Nombre visible de cada lado para la etiqueta de sección actual.
func _side_name(side: int) -> String:
	match side:
		SIDE_FRONT:
			return "PRINCIPAL"
		SIDE_LEFT:
			return "CORTE / DESMENUCE"
		SIDE_RIGHT:
			return "PREPARACIÓN"
		SIDE_BACK:
			return "ATRÁS"
	return "DESCONOCIDA"
