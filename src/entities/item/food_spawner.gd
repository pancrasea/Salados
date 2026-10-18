class_name FoodSpawner extends Node2D

## Repone alimentos arrastrables en una columna fija (zona izquierda).
## Cada slot corresponde a un ItemData de `foods`. Cuando el alimento es
## consumido (queue_free al soltarlo en la bandeja), el slot se rellena
## de nuevo tras `respawn_delay` segundos.
##
## Usa un Timer hijo por slot: si el spawner se libera, sus timers también,
## y así no quedan señales pendientes sobre instancias liberadas.

## Emitida cada vez que un alimento aparece en su slot.
signal food_spawned(food: ItemData, item: BaseItem)

## Alimentos ofrecidos, uno por slot (de arriba a abajo).
@export var foods: Array[ItemData] = []
## Escena instanciada por cada alimento; su raíz debe heredar de BaseItem.
@export var item_scene: PackedScene
## Segundos de espera antes de reponer un alimento consumido.
@export_range(0.0, 60.0, 0.1) var respawn_delay: float = 0.5
## Separación vertical entre slots, en píxeles.
@export_range(0.0, 512.0, 1.0) var slot_spacing: float = 150.0
## Desplazamiento del primer slot respecto al origen del spawner.
@export var first_slot_offset: Vector2 = Vector2(0.0, 100.0)
## Si está activo, rellena todos los slots al entrar en el árbol.
@export var spawn_on_ready: bool = true
## Si está activo, añade una etiqueta con el nombre bajo cada alimento.
@export var show_name_labels: bool = true
## Escala aplicada a cada alimento spawneado. Permite que una fuente compacta
## (p. ej. los agregados de la estación principal) muestre ítems pequeños sin
## encoger la escena base ni su colisión.
@export var item_scale: Vector2 = Vector2.ONE
## Origen del stock de la fuente:
## - INFINITE: repone sin límite (materia prima de prueba, platos).
## - PREPARADOS: se abastece de `GameManager.warehouse`; solo muestra un
##   ingrediente mientras la Sección 2 lo haya preparado, y descuenta una
##   unidad al consumirse (Sección 3).
## - MATERIA_PRIMA: se abastece de `GameManager.materia_prima`; respeta el
##   cupo diario de crudos (Sección 2) y descuenta una unidad al consumirse.
enum StockSource { INFINITE, PREPARADOS, MATERIA_PRIMA }

@export var stock_source: StockSource = StockSource.INFINITE

var _slot_timers: Array[Timer] = []
var _slot_instances: Array[BaseItem] = []
var _inventory: Inventario = null


func _ready() -> void:
	_slot_instances.resize(foods.size())
	_create_slot_timers()
	if stock_source != StockSource.INFINITE:
		_inventory = _resolve_inventory()
		if _inventory != null:
			_inventory.inventario_actualizado.connect(_on_stock_changed)
	if spawn_on_ready:
		refill()


## Resuelve el inventario desde el autoload GameManager. Se resuelve por ruta
## en vez del identificador global para que el script también compile en
## arranques headless con `--script`, donde los autoloads no se registran como
## globales.
func _resolve_inventory() -> Inventario:
	var game_manager := get_node_or_null("/root/GameManager")
	if game_manager == null:
		push_warning("FoodSpawner con stock sin GameManager; la fuente quedará vacía.")
		return null
	match stock_source:
		StockSource.PREPARADOS:
			return game_manager.get("warehouse") as Inventario
		StockSource.MATERIA_PRIMA:
			return game_manager.get("materia_prima") as Inventario
	return null


## Rellena todos los slots vacíos de inmediato (sin esperar el timer).
func refill() -> void:
	for index in foods.size():
		if not _is_slot_filled(index):
			_spawn(foods[index], index)


func _create_slot_timers() -> void:
	for index in foods.size():
		var timer := Timer.new()
		timer.one_shot = true
		timer.wait_time = maxf(respawn_delay, 0.05)
		# bind captura el valor de index en este instante: seguro en bucles.
		timer.timeout.connect(_on_slot_timeout.bind(index))
		add_child(timer)
		_slot_timers.append(timer)


func _is_slot_filled(index: int) -> bool:
	return index < _slot_instances.size() and is_instance_valid(_slot_instances[index])


func _spawn(food: ItemData, index: int) -> void:
	if item_scene == null or food == null:
		push_warning("FoodSpawner necesita item_scene y foods sin nulos.")
		return
	if stock_source != StockSource.INFINITE and (_inventory == null or not _inventory.tiene_stock(food)):
		return
	var item := item_scene.instantiate() as BaseItem
	if item == null:
		push_error("FoodSpawner.item_scene debe heredar de BaseItem.")
		return
	item.data = food
	item.scale = item_scale
	item.position = first_slot_offset + Vector2(0.0, index * slot_spacing)
	add_child(item)
	if show_name_labels:
		_add_name_label(item, food)
	item.tree_exited.connect(_on_food_exited.bind(index))
	_slot_instances[index] = item
	food_spawned.emit(food, item)


## Etiqueta de apoyo para identificar alimentos durante la jam.
func _add_name_label(item: BaseItem, food: ItemData) -> void:
	var label := Label.new()
	label.name = "NameLabel"
	label.text = food.name if food.name != "" else food.item_id
	label.position = Vector2(-48.0, 40.0)
	label.custom_minimum_size = Vector2(96.0, 0.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_child(label)


## Un alimento salió del árbol (consumido). Programa la reposición del slot.
func _on_food_exited(index: int) -> void:
	if not is_inside_tree() or index < 0 or index >= _slot_timers.size():
		return
	_slot_instances[index] = null
	if stock_source != StockSource.INFINITE and _inventory != null and index < foods.size():
		_inventory.consumir(foods[index])
	_slot_timers[index].start()


## El inventario cambió (algo se preparó o se consumió): rellena los huecos.
func _on_stock_changed(_item: ItemData, _cantidad: int) -> void:
	refill()


func _on_slot_timeout(index: int) -> void:
	if is_inside_tree() and not _is_slot_filled(index):
		refill()
