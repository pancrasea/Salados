extends CanvasLayer

@onready var left: Control = $left
@onready var right: Control = $right
@onready var buttom: Control = $buttom

func _on_left_mouse_entered() -> void:
    var station = GameManager.current_station
    if station:
        GameManager.load_scene(station.left_station)

func _on_right_mouse_entered() -> void:
    var station = GameManager.current_station
    if station:
        GameManager.load_scene(station.right_station)

func _on_buttom_mouse_entered() -> void:
    var station = GameManager.current_station
    if station:
        GameManager.load_scene(station.dowm_station)