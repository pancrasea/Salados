class_name FloatingText extends Label

## Texto flotante transitorio para feedback rápido de juego ("+$12",
## "¡No es lo que pidió!", "¡Se fue!"). Se anima subiendo y desvaneciéndose y
## se libera solo.
##
## Se crea con `spawn()`, que lo añade como hijo del nodo que lo origina para
## compartir su espacio de coordenadas (cliente, spawner de clientes, etc.).

static func spawn(
	parent: Node,
	local_pos: Vector2,
	texto: String,
	color: Color = Color.WHITE,
	font_size: int = 20,
	duracion: float = 1.1
) -> void:
	if not is_instance_valid(parent):
		return
	var etiqueta := FloatingText.new()
	etiqueta.text = texto
	etiqueta.position = local_pos
	etiqueta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	etiqueta.add_theme_font_size_override("font_size", font_size)
	etiqueta.add_theme_color_override("font_color", color)
	etiqueta.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	etiqueta.add_theme_constant_override("outline_size", 6)
	parent.add_child(etiqueta)
	etiqueta._animar(local_pos, duracion)


## Sube la etiqueta y la desvanece; al terminar se libera.
func _animar(base_pos: Vector2, duracion: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", base_pos + Vector2(0.0, -48.0), duracion)
	tween.parallel().tween_property(self, "modulate:a", 0.0, duracion).set_delay(duracion * 0.45)
	tween.tween_callback(queue_free)
