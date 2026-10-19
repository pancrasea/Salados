class_name DraggableZone extends Area2D

## Espacio de espera de platos terminados en la estación principal.
## Cada plato se instancia como BaseItem para combinarlo y entregarlo al cliente.
## La escena asignada debe tener BaseItem como raíz.
@export var item_scene: PackedScene

## La forma de MainStation.tscn admite ocho platos por fila y dos filas.
const COLUMNS: int = 8
const ROWS: int = 2
const SLOT_SPACING: Vector2 = Vector2(160.0, 130.0)
## Suelo visual de cada espacio: deja un margen entre vecinos.
const SLOT_FLOOR_SIZE: Vector2 = Vector2(142.0, 112.0)
const TOPPING_IDS = ["chifle", "limon", "maiz_tostado"]
## Los toppings nacen a escala 0.2 en Agregados; en el combo se ven al 30 %.
const COMBO_TOPPING_SCALE: float = 0.2 * 0.3

## Índice del espacio -> ítem activo; se libera cuando el ítem sale del árbol.
var _occupied: Dictionary[int, BaseItem] = {}
var _hovered_slot: int = -1


func _process(_delta: float) -> void:
	var hovered := -1
	if is_visible_in_tree():
		var mouse_position := to_local(get_global_mouse_position())
		for slot in _occupied:
			var item: BaseItem = _occupied[slot]
			if not is_instance_valid(item) or item.is_dragging:
				continue
			if _slot_rect(slot).has_point(mouse_position):
				hovered = slot
				break
	if hovered != _hovered_slot:
		_hovered_slot = hovered
		queue_redraw()


func _draw() -> void:
	for slot in _occupied:
		var item: BaseItem = _occupied[slot]
		if not is_instance_valid(item) or item.is_dragging:
			continue
		var floor_rect := _slot_rect(slot)
		var is_hovered := slot == _hovered_slot
		draw_rect(floor_rect, Color(0.24, 0.76, 0.35, 0.34 if is_hovered else 0.18), true)
		if is_hovered:
			draw_rect(floor_rect, Color(0.50, 1.0, 0.56, 0.9), false, 2.0)


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
	if item_data.item_id == "encebollado":
		# La clave vive en una copia: nunca se modifica el recurso compartido.
		item.data = item_data.duplicate() as ItemData
		var contents: Array[ItemData] = [item_data]
		item.data.recipe_key = OrderData.key_of_contents(contents)
	# El jugo de naranja usa un icono más grande que los demás productos.
	if item_data.item_id == "jugo_naranja":
		item.scale = Vector2.ONE * 0.5
	item.position = _slot_position(slot)
	_occupied[slot] = item
	add_child(item)
	queue_redraw()
	item.tree_exited.connect(_release_slot.bind(slot))
	# Las estaciones ocultas desactivan sus áreas en GameManager; este ítem
	# se creó después de ese cambio y debe esperar oculto también.
	if not is_visible_in_tree():
		var item_area := item.get_node_or_null("Area2D") as Area2D
		if item_area != null:
			item_area.set_deferred("monitoring", false)
			item_area.set_deferred("monitorable", false)
	return true


## Permite añadir jugo o toppings al plato sin repetir productos en el combo.
func can_combine(source: BaseItem, target: BaseItem) -> bool:
	if source == null or target == null or source == target:
		return false
	if target.get_parent() != self:
		return false
	if source.get_parent() != self and not (source.get_parent() is FoodSpawner):
		return false
	if source.data == null or target.data == null:
		return false
	if target.data.item_id != "encebollado" and target.data.item_id != "jugo_naranja":
		return false
	var ids: Array[String] = []
	var contents := _contents_of(target)
	contents.append_array(_contents_of(source))
	for ingredient in contents:
		if ingredient == null or ingredient.item_id in ids:
			return false
		if ingredient.item_id != "encebollado" and ingredient.item_id != "jugo_naranja" \
			and ingredient.item_id not in TOPPING_IDS:
			return false
		ids.append(ingredient.item_id)
	return ids.has("encebollado")


## El destino conserva su espacio; el origen se consume en BaseItem y libera el suyo.
func combine(source: BaseItem, target: BaseItem) -> bool:
	if not can_combine(source, target):
		return false
	var contents := _contents_of(target)
	contents.append_array(_contents_of(source))
	var dish_data: ItemData = null
	for ingredient in contents:
		if ingredient.item_id == "encebollado":
			dish_data = ingredient
			break
	target.data = dish_data.duplicate() as ItemData
	target.data.recipe_key = OrderData.key_of_contents(contents)
	target.bundled_ingredients = contents
	target.scale = Vector2.ONE
	target._update_visual()
	_update_combo_visual(target)
	queue_redraw()
	return true


func _contents_of(item: BaseItem) -> Array[ItemData]:
	if not item.bundled_ingredients.is_empty():
		return item.bundled_ingredients.duplicate()
	var contents: Array[ItemData] = [item.data]
	return contents


## Dibuja el jugo a la derecha y los toppings en una fila sobre el plato.
func _update_combo_visual(item: BaseItem) -> void:
	var juice_data: ItemData = null
	var toppings: Array[ItemData] = []
	for ingredient in item.bundled_ingredients:
		if ingredient.item_id == "jugo_naranja":
			juice_data = ingredient
		elif ingredient.item_id in TOPPING_IDS:
			toppings.append(ingredient)
	var has_juice := juice_data != null
	item.sprite_2d.position = Vector2(-32.0, 10.0) if has_juice else Vector2.ZERO
	if has_juice and item.get_node_or_null("ComboJugo") == null:
		var juice_sprite := Sprite2D.new()
		juice_sprite.name = "ComboJugo"
		juice_sprite.texture = juice_data.icon
		# El jugo individual está a 0.5; en el combo queda al 70 %.
		juice_sprite.scale = Vector2.ONE * 0.35
		juice_sprite.position = Vector2(40.0, -20.0)
		item.add_child(juice_sprite)
	var topping_row := item.get_node_or_null("ComboToppings") as Node2D
	if topping_row == null:
		topping_row = Node2D.new()
		topping_row.name = "ComboToppings"
		topping_row.z_index = 1
		item.add_child(topping_row)
	for child in topping_row.get_children():
		topping_row.remove_child(child)
		child.queue_free()
	for index in toppings.size():
		var topping_sprite := Sprite2D.new()
		topping_sprite.texture = toppings[index].icon
		topping_sprite.scale = Vector2.ONE * COMBO_TOPPING_SCALE
		topping_sprite.position = Vector2(
			item.sprite_2d.position.x + (index - (toppings.size() - 1) * 0.5) * 24.0,
			item.sprite_2d.position.y - 23.0
		)
		topping_row.add_child(topping_sprite)


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


func _slot_rect(slot: int) -> Rect2:
	return Rect2(_slot_position(slot) - SLOT_FLOOR_SIZE * 0.5, SLOT_FLOOR_SIZE)


func _release_slot(slot: int) -> void:
	_occupied.erase(slot)
	if _hovered_slot == slot:
		_hovered_slot = -1
	queue_redraw()
