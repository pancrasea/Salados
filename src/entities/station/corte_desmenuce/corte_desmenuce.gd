extends Station
class_name CorteDesmenuce

## SECCIÓN 2. Corte y desmenuce de la materia prima del encebollado.
## Recibe hasta tres ingredientes en la zona central mediante su DropArea.
## Cada uno requiere tres clics en el DropArea, en orden de izquierda a derecha. La señal
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

@onready var zona_central: ZonaProcesamiento = %ZonaCentral
@onready var drop_area: Area2D = $DropArea
@onready var drop_shape: CollisionShape2D = $DropArea/CollisionShape2D
@onready var mensaje: Label = %Mensaje
@onready var puntos: Label = %ProgresoPuntos
@onready var progreso: Label = %ProgresoTotal

func _ready() -> void:
	zona_central.ingrediente_terminado.connect(_cuando_termina_ingrediente)
	_refrescar_progreso()
	_refrescar_puntos()

## El clic puede caer sobre un icono: se detecta por posición dentro del área
## física y siempre avanza el primer ingrediente pendiente.
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not (event is InputEventMouseButton):
		return
	var click := event as InputEventMouseButton
	if click.button_index != MOUSE_BUTTON_LEFT or not click.pressed:
		return
	if BaseItem.current_item_dragging != null or not zona_central.esta_ocupada():
		return
	var rectangulo := drop_shape.shape as RectangleShape2D
	if rectangulo == null:
		return
	var posicion_local := drop_shape.to_local(get_global_mouse_position())
	if Rect2(-rectangulo.size / 2.0, rectangulo.size).has_point(posicion_local):
		zona_central.procesar_click()
		_refrescar_puntos()

## BaseItem llama recibir_item al soltarse sobre el Area2D DropArea.
func recibir_item(item: ItemData) -> bool:
	if item == null or item.next_data_state == null:
		return false

	var dato: EncebolladoIngrediente = _buscar_por_item(item)
	if dato == null or not dato.se_puede_preparar():
		return false

	if not zona_central.tiene_espacio():
		mensaje.text = "La zona está llena: prepara un ingrediente antes de añadir otro."
		return false

	# Sin espacio en la sección de preparación no se acepta otro crudo: evita
	# reservar más preparados de los que caben en el almacén.
	if not _hay_espacio(item):
		mensaje.text = "Sin espacio en preparación: consume los ingredientes preparados."
		return false

	# BaseItem consume el nodo arrastrable; cada espacio conserva su ItemData.
	zona_central.empezar(dato)
	_sincronizar_entrada_activa()
	_refrescar_puntos()
	mensaje.text = "%s añadido (%d/3). Haz clic en la zona central para prepararlo." % [
		dato.nombre_visible, zona_central.cantidad_en_fila()]
	return true

func _buscar_por_item(item: ItemData) -> EncebolladoIngrediente:
	for recurso in RECETAS:
		var dato: EncebolladoIngrediente = recurso as EncebolladoIngrediente
		if dato != null and dato.item_entrada == item:
			return dato
	return null

func _buscar_por_id(id: StringName) -> EncebolladoIngrediente:
	for recurso in RECETAS:
		var dato: EncebolladoIngrediente = recurso as EncebolladoIngrediente
		if dato != null and dato.id == id:
			return dato
	return null

## Compatibilidad con los campos públicos: señalan el primer crudo pendiente.
func _sincronizar_entrada_activa() -> void:
	var primero := zona_central.primer_pendiente()
	entrada_activa = primero.item_entrada if primero != null else null
	ingrediente_activo = primero.id if primero != null else &""

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
	return almacen.hay_espacio(salida, zona_central.pendientes_de(item_entrada) + 1)

func _cuando_termina_ingrediente(id: StringName) -> void:
	var dato := _buscar_por_id(id)
	var salida: ItemData = dato.item_entrada.next_data_state if dato != null else null
	_sincronizar_entrada_activa()
	if salida == null:
		mensaje.text = "No se encontró el estado preparado del ingrediente."
		return
	total_procesados += 1
	_refrescar_progreso()
	mensaje.text = "%s listo: enviado a la sección de preparación." % salida.name
	item_preparado.emit(salida)

func _refrescar_progreso() -> void:
	progreso.text = "Total preparado: %d" % total_procesados

func _refrescar_puntos() -> void:
	puntos.text = zona_central.puntos_progreso()
