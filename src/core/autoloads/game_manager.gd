extends Node

var current_station : Station = null

func set_current_station(cs: Station) -> void:
	current_station = cs

func load_scene(_scene : PackedScene) -> void:
	pass