class_name FoodSpawner extends Node2D

## Repone alimentos arrastrables en una zona fija.
## Cada ItemData de `foods` ocupa `slots_per_item` slots. Con `slots_per_item`
## en 1 y `horizontal_groups` desactivado se comporta como una columna clásica
## (un slot por alimento). Con `horizontal_groups` activo, los slots de un
## mismo alimento se alinean en horizontal (una fila por alimento) y los
## alimentos se apilan hacia abajo usando `row_spacing`.
## Cuando el alimento es consumido (queue_free al soltarlo), su slot se
## rellena de nuevo tras `respawn_delay` segundos.
##
## Usa un Timer hijo por slot: si el spawner se libera, sus timers también,
## y así no quedan señales pendientes sobre instancias liberadas.

## Emitida cada vez que un alimento aparece en su slot.
signal food_spawned(food: ItemData, item: BaseItem)

## Alimentos ofrecidos; cada uno ocupa `slots_per_item` slots.
@export var foods: Array[ItemData] = []
## Escena instanciada por cada alimento; su raíz debe heredar de BaseItem.
@export var item_scene: PackedScene
## Segundos de espera antes de reponer un alimento consumido.
@export_range(0.0, 60.0, 0.1) var respawn_delay: float = 0.5
## Separación entre slots: vertical en la columna clásica u horizontal entre
## los slots de un mismo alimento cuando `horizontal_groups` está activo.
@export_range(0.0, 512.0, 1.0) var slot_spacing: float = 150.0
## Desplazamiento del primer slot respecto al origen del spawner.
@export var first_slot_offset: Vector2 = Vector2(0.0, 100.0)
## Si está activo, rellena todos los slots al entrar en el árbol.
@export var spawn_on_ready: bool = true
## Si está activo, añade una etiqueta con el nombre bajo cada alimento.
@export var show_name_labels: bool = true
## Escala aplicada a cada alimento spawneado, incluida su colisión.
@export var item_scale: Vector2 = Vector2.ONE * 1
## Multiplica solo el sprite del alimento; el Area2D conserva su tamaño.
@export_range(0.1, 4.0, 0.1) var item_visual_scale: float = 1.0
## Slots (unidades visibles) por cada ItemData de `foods`. Acota cuántas
## unidades del mismo ingrediente se muestran a la vez.
@export_range(1, 6, 1) var slots_per_item: int = 1
## Si está activo, los slots de cada alimento se alinean en horizontal (una
## fila por alimento) y los alimentos se apilan en `row_spacing`. Si no, se usa
## la columna vertical clásica.
@export var horizontal_groups: bool = false
## Separación vertical entre filas de alimentos (solo con `horizontal_groups`).
@export_range(0.0, 512.0, 1.0) var row_spacing: float = 120.0
## Origen del stock de la fuente:
## - INFINITE: repone sin límite (materia prima de prueba, platos).
## - PREPARADOS: se abastece de `GameManager.warehouse`; muestra hasta
##   `slots_per_item` unidades por ingrediente mientras la Sección 2 lo haya
##   preparado, y descuenta una unidad al consumirse (Sección 3).
## - MATERIA_PRIMA: se abastece de `GameManager.materia_prima`; respeta el
##   cupo diario de crudos (Sección 2) y descuenta una unidad al consumirse.
enum StockSource { INFINITE, PREPARADOS, MATERIA_PRIMA }

@export var stock_source: StockSource = StockSource.INFINITE

var _slot_timers: Array[Timer] = []
var _slot_instances: Array[BaseItem] = []
## Etiquetas del stock por slot, hijas de la fuente para no seguir al ítem.
var _stock_labels: Array[Label] = []
var _inventory: Inventario = null
## Evita que el refill inmediato dispare al consumir un ítem: al descontar el
## inventario se emite `inventario_actualizado`, pero el hueco debe reponerse
## tras `respawn_delay`, no al instante.
var _consuming: bool = false


func _ready() -> void:
	_slot_instances.resize(_slot_count())
	_stock_labels.resize(_slot_count())
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
	for flat_index in _slot_instances.size():
		if _is_slot_filled(flat_index):
			continue
		var item_index := _item_index(flat_index)
		if item_index < foods.size():
			_spawn(foods[item_index], flat_index)


## Número total de slots (alimentos × slots por alimento).
func _slot_count() -> int:
	return foods.size() * _per_item()


## Slots por alimento (mínimo 1).
func _per_item() -> int:
	return maxi(slots_per_item, 1)


## Índice del ItemData (en `foods`) al que pertenece un slot.
func _item_index(flat_index: int) -> int:
	return int(flat_index / float(_per_item()))


## Posición local del slot según el layout configurado.
func _slot_position(flat_index: int) -> Vector2:
	if horizontal_groups:
		var slot_j := flat_index % _per_item()
		return first_slot_offset + Vector2(slot_j * slot_spacing, _item_index(flat_index) * row_spacing)
	return first_slot_offset + Vector2(0.0, flat_index * slot_spacing)


## Cuántos slots ocupados tiene un alimento actualmente.
func _filled_for_item(item_index: int) -> int:
	var total := 0
	var base := item_index * _per_item()
	for offset in _per_item():
		if _is_slot_filled(base + offset):
			total += 1
	return total


func _create_slot_timers() -> void:
	for flat_index in _slot_count():
		var timer := Timer.new()
		timer.one_shot = true
		timer.wait_time = maxf(respawn_delay, 0.05)
		# bind captura el valor de flat_index en este instante: seguro en bucles.
		timer.timeout.connect(_on_slot_timeout.bind(flat_index))
		add_child(timer)
		_slot_timers.append(timer)


func _is_slot_filled(flat_index: int) -> bool:
	return flat_index >= 0 and flat_index < _slot_instances.size() \
		and is_instance_valid(_slot_instances[flat_index])


func _spawn(food: ItemData, flat_index: int) -> void:
	if item_scene == null or food == null:
		push_warning("FoodSpawner necesita item_scene y foods sin nulos.")
		return
	if stock_source != StockSource.INFINITE:
		if _inventory == null:
			return
		# Se muestran hasta `slots_per_item` unidades, acotadas por el stock.
		var capacidad := mini(_inventory.cantidad_de(food), _per_item())
		if _filled_for_item(_item_index(flat_index)) >= capacidad:
			return
	var item := item_scene.instantiate() as BaseItem
	if item == null:
		push_error("FoodSpawner.item_scene debe heredar de BaseItem.")
		return
	item.data = food
	item.scale = item_scale
	item.position = _slot_position(flat_index)
	add_child(item)
	if item.sprite_2d != null:
		item.sprite_2d.scale *= item_visual_scale
	if show_name_labels:
		_add_name_label(item, food)
	if stock_source == StockSource.MATERIA_PRIMA:
		_add_stock_label(flat_index, food)
	item.tree_exited.connect(_on_food_exited.bind(flat_index))
	_slot_instances[flat_index] = item
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


## Conserva el contador en la posición del slot aunque el crudo se arrastre.
func _add_stock_label(flat_index: int, food: ItemData) -> void:
	var label := _stock_labels[flat_index]
	if label == null:
		label = Label.new()
		label.name = "StockLabel_%d" % flat_index
		label.position = _slot_position(flat_index) + Vector2(48.0, 40.0) * item_scale
		label.scale = item_scale
		label.z_index = 1
		label.custom_minimum_size = Vector2(64.0, 0.0)
		label.add_theme_font_size_override("font_size", 24)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(label)
		_stock_labels[flat_index] = label
	_update_stock_label(label, food)


func _update_stock_label(label: Label, food: ItemData) -> void:
	var game_manager := get_node_or_null("/root/GameManager")
	var balance: RunBalance = null
	if game_manager != null:
		balance = game_manager.get("balance") as RunBalance
	var limite := balance.limite_de(food) if balance != null else 0
	var restante := _inventory.cantidad_de(food) if _inventory != null else 0
	label.text = "%d/%d" % [restante, limite]
	label.visible = restante > 0


func _refresh_stock_labels() -> void:
	for slot in _stock_labels.size():
		var label := _stock_labels[slot]
		if label != null:
			_update_stock_label(label, foods[_item_index(slot)])


## Un alimento salió del árbol (consumido). Descuenta el stock y programa la
## reposición del slot.
func _on_food_exited(flat_index: int) -> void:
	if not is_inside_tree() or flat_index < 0 or flat_index >= _slot_timers.size():
		return
	_slot_instances[flat_index] = null
	var item_index := _item_index(flat_index)
	if stock_source != StockSource.INFINITE and _inventory != null and item_index < foods.size():
		_consuming = true
		_inventory.consumir(foods[item_index])
		_consuming = false
	_slot_timers[flat_index].start()


## El inventario cambió (algo se preparó, o se consumió desde otra fuente):
## rellena los huecos, salvo cuando el cambio viene de consumir en esta fuente
## (entonces la reposición la controla el timer del slot).
func _on_stock_changed(_item: ItemData, _cantidad: int) -> void:
	if stock_source == StockSource.MATERIA_PRIMA:
		_refresh_stock_labels()
	if _consuming:
		return
	refill()


func _on_slot_timeout(flat_index: int) -> void:
	if is_inside_tree() and not _is_slot_filled(flat_index):
		refill()
