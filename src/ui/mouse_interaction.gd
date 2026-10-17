extends CanvasLayer

@onready var left: Control = $left
@onready var right: Control = $right
@onready var buttom: Control = $buttom

func _on_left_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		print("LEFT")
		GameManager.turn_left()

func _on_right_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		print("RIGHT")
		GameManager.turn_right()

func _on_buttom_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		print("BACK")
		GameManager.turn_back()
