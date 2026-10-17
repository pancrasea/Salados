class_name BaseItem extends Node2D

@export var data: ItemData

var is_dragging: bool = false
var collected_ingredients: Array[ItemData] = []
var initial_position: Vector2 = Vector2.ZERO
static var current_item_dragging: BaseItem = null

@onready var sprite_2d: Sprite2D = $Sprite2D

# Contenedor visual de los badges de ingredientes (opción "icono base +
# badges"): se crea en runtime porque la escena no lo define.
var _badges_root: Node2D


func _ready() -> void:
	if data and data.is_container:
		# Duplicamos el recurso para mutar recipe_key/ingredientes sin tocar
		# el .tres compartido que usan pedidos y otros ítems. Contenido
		# vacío => clave vacía (no coincide con ningún pedido).
		data = data.duplicate()
		data.recipe_key = OrderData.key_of_contents(collected_ingredients)
	if data:
		_update_visual()

func _update_visual():
	if sprite_2d:
		if data and data.icon:
			sprite_2d.texture = data.icon
		else:
			sprite_2d.texture = null
	_update_badges()

func _process(delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position()

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			if BaseItem.current_item_dragging == null or BaseItem.current_item_dragging == self:
				BaseItem.current_item_dragging = self
				is_dragging = true
				initial_position = global_position
				z_index = 100
		else:
			if is_dragging:
				is_dragging = false
				BaseItem.current_item_dragging = null
				z_index = 0
				_verify_target_and_drop()

func _verify_target_and_drop():
	var overlapping_areas = $Area2D.get_overlapping_areas()
	var successful_drop = false
	
	for area in overlapping_areas:
		var target = area.get_parent()
		
		if target == self:
			continue
		
		# Caso contenedor (plato o vaso): el ingrediente se consume.
		if target is BaseItem and target.data and target.data.is_container:
			target.collect_ingredients(self.data)
			successful_drop = true
			queue_free()
			break

		# Caso tacho de basura: descarta el pedido preparado (bandeja vacía
		# o alimento consumido).
		if target is TrashBin:
			if target.discard(self):
				successful_drop = true
				break

		# Deliver the item's definition, not its scene node, to a customer.
		if target is CustomerBase and data != null:
			if target.receive_item(data):
				successful_drop = true
				if data.is_container:
					# La bandeja es reutilizable: al servir se vacía y
					# vuelve a su posición inicial en lugar de consumirse.
					reset_container()
				else:
					queue_free()
				break
		
		#TODO: Caso de las estaciones de trabajo
		
	if not successful_drop:
		global_position = initial_position
	
	

## Añade un ingrediente a la bandeja, recalcula su clave canónica y refresca
## los badges visuales. La clave se deduplica: agregar pan dos veces no
## cambia la identidad del plato (ver OrderData.key_of_contents).
func collect_ingredients(new_ingredient: ItemData):
	if data and data.is_container and not data.is_final_product and new_ingredient != null:
		collected_ingredients.append(new_ingredient)
		data.recipe_key = OrderData.key_of_contents(collected_ingredients)
		_update_visual()


## Vacía la bandeja y la devuelve a su última posición inicial. Se llama
## tras servir al cliente para poder preparar el siguiente pedido.
func reset_container() -> void:
	if not collected_ingredients.is_empty():
		collected_ingredients.clear()
	if data:
		data.recipe_key = ""
	_update_visual()
	global_position = initial_position


## Dibuja un badge pequeño por cada ingrediente recolectado, en fila
## horizontal bajo el sprite de la bandeja. Los ingredientes sin icono se
## omiten (la identidad vive en recipe_key, no en el badge).
func _update_badges() -> void:
	if _badges_root == null:
		_badges_root = Node2D.new()
		_badges_root.name = "Badges"
		add_child(_badges_root)
	for child in _badges_root.get_children():
		child.queue_free()
	if data == null or not data.is_container:
		return
	var count := collected_ingredients.size()
	for index in count:
		var icon: Texture2D = collected_ingredients[index].icon
		if icon == null:
			continue
		var badge := Sprite2D.new()
		badge.texture = icon
		badge.scale = Vector2(0.2, 0.2)
		badge.position = Vector2((index - (count - 1) * 0.5) * 20.0, 56.0)
		_badges_root.add_child(badge)
