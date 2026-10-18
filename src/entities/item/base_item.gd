class_name BaseItem extends Node2D

@export var data: ItemData

## Receta que este contenedor puede completar: cuando reúne exactamente sus
## `require_ingredients` (como conjunto, sin importar el orden), el ítem se
## transforma en `recipe.final_product`. Opcional; solo lo usan los platos de
## preparación (ver `plato_item.tscn`). La bandeja va sin receta.
@export var recipe: RecipeData

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
	$Area2D.mouse_entered.connect(_on_area_mouse_entered)
	$Area2D.mouse_exited.connect(_on_area_mouse_exited)

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
		_update_drop_highlights()

## Áreas válidas bajo el ítem mientras se arrastra; se resaltan en `_draw`.
var _valid_areas: Array[Area2D] = []

## Recalcula los destinos válidos bajo el ítem y pide repintar el resaltado.
func _update_drop_highlights() -> void:
	_valid_areas.clear()
	for area in $Area2D.get_overlapping_areas():
		if _is_valid_drop_target(area.get_parent()):
			_valid_areas.append(area)
	queue_redraw()

## ¿El nodo es un destino válido para este ítem? Replica las reglas de
## `_verify_target_and_drop` sin mutar estado, para anticipar al jugador.
func _is_valid_drop_target(target: Node) -> bool:
	if target == null or target == self:
		return false
	if target is WorkSurface:
		return true
	if target is BaseItem:
		var contenedor := target as BaseItem
		return contenedor.data != null and contenedor.data.is_container \
			and contenedor.data.item_id != "exprimidor"
	if target is TrashBin:
		return true
	if target is CustomerBase:
		return data != null and (target as CustomerBase).can_receive(data)
	if target is DispatchZone:
		return data != null and data.is_final_product
	if target is CorteDesmenuce:
		return data != null and data.next_data_state != null
	return false

## Dibuja un aro sobre cada destino válido bajo el ítem arrastrado.
func _draw() -> void:
	if not is_dragging:
		return
	var color := Color(0.55, 0.92, 0.62, 0.9)
	for area in _valid_areas:
		if not is_instance_valid(area):
			continue
		var centro: Vector2 = area.global_position - global_position
		draw_arc(centro, 46.0, 0.0, TAU, 40, color, 5.0, true)

func _on_area_mouse_entered() -> void:
	if BaseItem.current_item_dragging == null:
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_area_mouse_exited() -> void:
	if BaseItem.current_item_dragging == null:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _exit_tree() -> void:
	if BaseItem.current_item_dragging == null:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			if BaseItem.current_item_dragging == null or BaseItem.current_item_dragging == self:
				BaseItem.current_item_dragging = self
				is_dragging = true
				initial_position = global_position
				z_index = 100
				Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
		else:
			if is_dragging:
				is_dragging = false
				BaseItem.current_item_dragging = null
				z_index = 0
				_valid_areas.clear()
				queue_redraw()
				Input.set_default_cursor_shape(Input.CURSOR_ARROW)
				_verify_target_and_drop()

func _verify_target_and_drop():
	var overlapping_areas = $Area2D.get_overlapping_areas()
	var successful_drop = false
	# Evita repetir el aviso si varios clientes rechazan el mismo ítem.
	var rejected_feedback := false
	# La mesa (WorkSurface) es un destino de reserva: sólo mantiene el ítem
	# si ningún otro destino lo atendió, para no competir con ellos.
	var on_work_surface := false
	
	for area in overlapping_areas:
		var target = area.get_parent()
		
		if target == self:
			continue

		if target is WorkSurface:
			on_work_surface = true
			continue
		
		# Caso contenedor (plato o vaso): el ingrediente se consume.
		if target is BaseItem and target.data and target.data.is_container:
			if target.data.item_id == "exprimidor":
				break
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
			elif not rejected_feedback:
				# El cliente no aceptó: avisar para que no parezca un fallo mudo.
				FloatingText.spawn(target, Vector2(0.0, -150.0), "¡No es lo que pidió!", Color(0.96, 0.5, 0.45))
				rejected_feedback = true

		# Zona de despacho de preparación: envía el plato listo a la
		# estación principal (bandeja) para agregarle los extras.
		if target is DispatchZone:
			if target.dispatch(self):
				successful_drop = true
				break

		# Zona de corte/desmenuce (Sección 2): el ingrediente crudo entra a la
		# estación que lo procesa. El nodo se consume; el ItemData queda en la
		# estación hasta completar los clics.
		if target is CorteDesmenuce:
			if target.recibir_item(data):
				successful_drop = true
				queue_free()
				break

	# Sobre una mesa de trabajo el ítem se queda donde el jugador lo dejó.
	if not successful_drop and on_work_surface:
		successful_drop = true

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
		_try_complete_recipe()


## Si este contenedor tiene una `recipe` y su contenido coincide con el
## conjunto de `require_ingredients`, se transforma en el producto final.
## La comparación es por clave canónica (OrderData.key_of_contents), así que
## el orden en que se agregaron los ingredientes es irrelevante y agregar un
## ingrediente ajeno impide la transformación.
func _try_complete_recipe() -> void:
	if recipe == null or recipe.final_product == null:
		return
	if OrderData.key_of_contents(collected_ingredients) != OrderData.key_of_contents(recipe.require_ingredients):
		return
	_transform_into(recipe.final_product)


## Convierte el ítem en `product` (plato terminado): deja de ser contenedor y
## pierde sus ingredientes. No muta `product` (es un .tres compartido).
func _transform_into(product: ItemData) -> void:
	collected_ingredients.clear()
	data = product
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
