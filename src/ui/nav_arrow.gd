extends Control

## Flecha visible de los botones de navegación entre secciones. Se dibuja con
## polígonos centrados en el control, sin depender de fuentes ni texturas, para
## que las zonas de clic de `mouse_interaction` (los cuatro lados) se
## vean siempre. `mouse_filter` debe ser IGNORE: el clic lo recibe el
## TextureButton padre.

## Dirección a la que apunta la flecha.
@export_enum("Izquierda:0", "Derecha:1", "Abajo:2", "Arriba:3") var direccion: int = 0
## Tamaño (ancho/alto) del triángulo dibujado, en píxeles.
@export var tamano: float = 46.0
## Color de relleno de la flecha.
@export var color: Color = Color(0.96, 0.9, 0.72, 0.95)
## Color del borde de la flecha.
@export var color_borde: Color = Color(0.1, 0.08, 0.06, 0.85)
## Color del disco de fondo que mejora el contraste sobre la escena.
@export var color_fondo: Color = Color(0.06, 0.09, 0.1, 0.45)


func _ready() -> void:
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var centro := size * 0.5
	var mitad := tamano * 0.5
	var puntos: PackedVector2Array
	match direccion:
		0:
			puntos = PackedVector2Array([
				centro + Vector2(mitad, -mitad),
				centro + Vector2(mitad, mitad),
				centro + Vector2(-mitad, 0.0),
			])
		1:
			puntos = PackedVector2Array([
				centro + Vector2(-mitad, -mitad),
				centro + Vector2(-mitad, mitad),
				centro + Vector2(mitad, 0.0),
			])
		2:
			puntos = PackedVector2Array([
				centro + Vector2(-mitad, -mitad),
				centro + Vector2(mitad, -mitad),
				centro + Vector2(0.0, mitad),
			])
		_:
			puntos = PackedVector2Array([
				centro + Vector2(-mitad, mitad),
				centro + Vector2(mitad, mitad),
				centro + Vector2(0.0, -mitad),
			])
	draw_circle(centro, mitad + 8.0, color_fondo)
	draw_colored_polygon(puntos, color)
	var contorno := puntos.duplicate()
	contorno.append(puntos[0])
	draw_polyline(contorno, color_borde, 3.0, true)
