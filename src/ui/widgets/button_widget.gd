extends Control

@onready var icono : TextureRect = $HBoxContainer/TextureRect
@onready var boton : TextureButton = $HBoxContainer/TextureButton

var tween : Tween

func _ready() -> void:
	icono.modulate.a = 0.0

func _reset_tween():
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()

func _on_mouse_entered() -> void:
	icono.modulate.a = 1.0
	AudioManager.play_sound(AudioManager.SFX.UI_HOVER)

	_reset_tween()
	tween.tween_property(boton, "offset_transform_scale:x", 1.1, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

func _on_mouse_exited() -> void:
	icono.modulate.a = 0.0
	
	_reset_tween()
	tween.tween_property(boton, "offset_transform_scale:x", 1.0, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)