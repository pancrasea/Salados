extends Node

var current_level: Level = null
var current_station: Station = null

func load_level(level: Level):
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