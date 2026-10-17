extends HBoxContainer

@onready var icono = $TextureRect
@onready var boton = $Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	icono.visible = false
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_button_mouse_exited() -> void:
	icono.visible = false

func _on_button_mouse_entered() -> void:
	icono.visible = true
