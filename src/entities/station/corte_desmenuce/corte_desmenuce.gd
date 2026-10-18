extends Station
class_name CorteDesmenuce

## SECCIÓN 2. Corte y desmenuce de la materia prima del encebollado.
## Recibe UN ingrediente por vez sobre su DropArea (ver BaseItem), que llama
## `recibir_item`, y permite preparar cantidades ilimitadas. La señal
## `item_preparado` entrega el ItemData ya preparado (con item_id) para que el
## almacén lo acumule y la sección de preparación lo consuma.
signal item_preparado(item: ItemData)

## Reglas de preparación admitidas. Cada regla enlaza un item de entrada con su
## `next_data_state` (el item preparado). El cilantro queda fuera del flujo.
const RECETAS: Array[Resource] = [
	preload("res://resources/items/encebollado_cebolla_colorada.tres"),
	preload("res://resources/items/encebollado_albacora.tres"),
	preload("res://resources/items/encebollado_yuca.tres")
]

var entrada_activa: ItemData = null
var ingrediente_activo: StringName = &""
var total_procesados: int = 0

@onready var zona_corte: ZonaProcesamiento = %ZonaCorte
@onready var zona_desmenuce: ZonaProcesamiento = %ZonaDesmenuce
@onready var mensaje: Label = %Mensaje
@onready var progreso: Label = %ProgresoTotal

func _ready() -> void:
	zona_corte.ingrediente_terminado.connect(_cuando_termina_ingrediente)
	zona_desmenuce.ingrediente_terminado.connect(_cuando_termina_ingrediente)
	_refrescar_progreso()

## BaseItem llama recibir_item al soltarse sobre el Area2D DropArea.
func recibir_item(item: ItemData) -> bool:
	if item == null or item.next_data_state == null:
		return false

	var dato: EncebolladoIngrediente = _buscar_por_item(item)
	if dato == null or not dato.se_puede_preparar():
		return false

	# Sin espacio en la sección de preparación no se acepta otro crudo: evita
	# acumular preparados que no cabrían en la fuente `Ingredientes`.
	if not _hay_espacio(item):
		mensaje.text = "Sin espacio en preparación: consume los ingredientes preparados."
		return false

	# No duplicar la preparación mientras ya hay un ingrediente en curso.
	if ingrediente_activo != &"":
		return false

	var zona: ZonaProcesamiento = _zona_para(dato)
	if zona == null or zona.esta_ocupada():
		return false

	entrada_activa = item
	ingrediente_activo = dato.id
	zona.empezar(dato)
	mensaje.text = "%s: haz %d clics para %s." % [
		dato.nombre_visible,
		dato.clics_necesarios,
		"cortar" if dato.preparacion == EncebolladoIngrediente.Preparacion.CORTAR else "desmenuzar"
	]
	return true

func _zona_para(dato: EncebolladoIngrediente) -> ZonaProcesamiento:
	if dato.preparacion == EncebolladoIngrediente.Preparacion.CORTAR:
		return zona_corte
	if dato.preparacion == EncebolladoIngrediente.Preparacion.DESMENUZAR:
		return zona_desmenuce
	return null

func _buscar_por_item(item: ItemData) -> EncebolladoIngrediente:
	for recurso in RECETAS:
		var dato: EncebolladoIngrediente = recurso as EncebolladoIngrediente
		if dato != null and dato.item_entrada == item:
			return dato
	return null

## True si el almacén de la Sección 3 admite otra unidad del preparado de
## `item_entrada`. Resuelve `GameManager` por ruta para funcionar también en
## arranques headless con `--script`. Sin GameManager se permite (pruebas).
func _hay_espacio(item_entrada: ItemData) -> bool:
	var salida: ItemData = item_entrada.next_data_state
	if salida == null:
		return true
	var game_manager := get_node_or_null("/root/GameManager")
	if game_manager == null:
		return true
	var almacen := game_manager.get("warehouse") as Inventario
	if almacen == null:
		return true
	return almacen.hay_espacio(salida)

func _cuando_termina_ingrediente(id: StringName) -> void:
	if entrada_activa == null or ingrediente_activo != id:
		return
	var salida: ItemData = entrada_activa.next_data_state
	# Limpiamos para admitir otra cebolla, yuca, etc. sin límite.
	entrada_activa = null
	ingrediente_activo = &""
	if salida == null:
		mensaje.text = "No se encontró el estado preparado del ingrediente."
		return
	total_procesados += 1
	_refrescar_progreso()
	mensaje.text = "%s listo: enviado a la sección de preparación." % salida.name
	item_preparado.emit(salida)

func _refrescar_progreso() -> void:
	progreso.text = "Total preparado: %d" % total_procesados
