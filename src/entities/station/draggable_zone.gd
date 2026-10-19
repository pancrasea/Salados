class_name DraggableZone extends Area2D

## Espacio de espera de platos terminados en la estación principal.
## Cada plato se instancia como BaseItem para poder arrastrarlo a la bandeja.
## La escena asignada debe tener BaseItem como raíz.
@export var item_scene: PackedScene

## La forma de MainStation.tscn admite ocho platos por fila y dos filas.
const COLUMNS: int = 8
const ROWS: int = 2
const SLOT_SPACING: Vector2 = Vector2(160.0, 130.0)

## Índice del espacio -> ítem activo; se libera cuando el ítem sale del árbol.
var _occupied: Dictionary[int, BaseItem] = {}


## Coloca un producto final en el primer espacio libre. Devuelve false si
## el área está llena, para que el despacho conserve el plato de origen.
func receive(item_data: ItemData) -> bool:
	if item_data == null or not item_data.is_final_product:
		return false
	var slot := _first_free_slot()
	if slot < 0:
		return false
	if item_scene == null:
		return false
	var item := item_scene.instantiate() as BaseItem
	if item == null:
		return false
	item.data = item_data
	# El jugo de naranja usa un icono más grande que los demás productos.
	if item_data.item_id == "jugo_naranja":
		item.scale = Vector2.ONE * 0.5
	item.position = _slot_position(slot)
	_occupied[slot] = item
	add_child(item)
	item.tree_exited.connect(_release_slot.bind(slot))
	# Las estaciones ocultas desactivan sus áreas en GameManager; este ítem
	# se creó después de ese cambio y debe esperar oculto también.
	if not is_visible_in_tree():
		var item_area := item.get_node_or_null("Area2D") as Area2D
		if item_area != null:
			item_area.set_deferred("monitoring", false)
			item_area.set_deferred("monitorable", false)
	return true


func _first_free_slot() -> int:
	for slot in COLUMNS * ROWS:
		if not _occupied.has(slot):
			return slot
	return -1


func _slot_position(slot: int) -> Vector2:
	var column := slot % COLUMNS
	var row := int(slot / COLUMNS)
	var center := ($CollisionShape2D as CollisionShape2D).position
	return center + Vector2(
		(column - (COLUMNS - 1) * 0.5) * SLOT_SPACING.x,
		(row - (ROWS - 1) * 0.5) * SLOT_SPACING.y
	)


func _release_slot(slot: int) -> void:
	_occupied.erase(slot)
