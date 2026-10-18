extends Node

var current_level: Level = null
var current_station: Station = null

# Referencia al nodo Main (asignada por main.gd en _ready)
var main: Control = null


# --- Cambio de pantallas ---

func go_to_game() -> void:
	if is_instance_valid(main):
		main.change_screen(main.TESTING_LEVEL_SCENE)

func go_to_menu() -> void:
	if is_instance_valid(main):
		main.change_screen(main.MAIN_MENU_SCENE)


# --- Lógica de nivel ---

func load_level(level: Level) -> void:
	if not is_instance_valid(level): return
	current_level = level
	current_level.show_side(Level.Side.FRONT)

func turn_left() -> void:
	if is_instance_valid(current_level):
		current_level.turn_view(Level.Turn.LEFT)

func turn_right() -> void:
	if is_instance_valid(current_level):
		current_level.turn_view(Level.Turn.RIGHT)

func turn_back() -> void:
	if is_instance_valid(current_level):
		current_level.turn_view(Level.Turn.BACK)
