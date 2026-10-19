extends Node2D

var completados: int = 0
var fallos: int = 0

func _ready() -> void:
	_probar()

func _probar() -> void:
	var escena := load("res://src/entities/station/corte_desmenuce/CorteDesmenuce.tscn") as PackedScene
	var estacion := escena.instantiate() as CorteDesmenuce
	add_child(estacion)
	await get_tree().process_frame
	estacion.item_preparado.connect(_al_preparar)
	var zona := estacion.zona_central
	var cebolla := load("res://resources/items/item_cebolla_colorada.tres") as ItemData
	var yuca := load("res://resources/items/item_yuca.tres") as ItemData
	var albacora := load("res://resources/items/item_albacora.tres") as ItemData
	_comprobar(estacion.recibir_item(cebolla), "cebolla aceptada")
	_comprobar(estacion.recibir_item(yuca), "yuca aceptada")
	_comprobar(estacion.recibir_item(albacora), "albacora aceptada")
	_comprobar(not estacion.recibir_item(cebolla), "cuarto ingrediente rechazado")
	_comprobar(zona.cantidad_en_fila() == 3, "tres ingredientes en fila")
	_comprobar(zona.puntos_progreso().split(" ").size() == 9, "nueve puntos")
	for i in range(9):
		zona.procesar_click()
		_comprobar(completados == floori(float(i + 1) / 3.0), "preparados tras clic %d" % (i + 1))
	_comprobar(zona.cantidad_en_fila() == 0, "fila vacía tras nueve clics")
	_comprobar(zona.puntos_progreso() == "", "puntos vacíos al terminar")
	print("Prueba fila corte: %d fallos" % fallos)
	get_tree().quit(fallos)

func _al_preparar(_item: ItemData) -> void:
	completados += 1

func _comprobar(condicion: bool, descripcion: String) -> void:
	if not condicion:
		fallos += 1
		push_error(descripcion)
