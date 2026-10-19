extends CanvasLayer

## Controles de navegación entre secciones. Los botones de borde y las teclas
## A/D o flechas izquierda/derecha giran con GameManager; la flecha inferior
## conserva el giro hacia atrás. La etiqueta indica la sección actual.

@onready var left: Control = $left
@onready var right: Control = $right
@onready var buttom: Control = $buttom
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


## Atajos activos solo mientras se juega; ignora repeticiones al mantener
## la tecla pulsada para que cada pulsación intente un único giro.
func _input(event: InputEvent) -> void:
	if not visible or get_tree().paused:
		return
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_A, KEY_LEFT:
			_turn("turn_left")
		KEY_D, KEY_RIGHT:
			_turn("turn_right")
		_:
			return
	get_viewport().set_input_as_handled()


func _on_left_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_turn("turn_left")


func _on_right_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_turn("turn_right")


func _on_buttom_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_turn("turn_back")


## Gira la estación delegando en GameManager (resuelto por ruta para funcionar
## también en arranques headless con `--script`).
func _turn(method: String) -> void:
	if _game_manager != null:
		_game_manager.call(method)


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
