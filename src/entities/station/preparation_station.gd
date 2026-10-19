extends Station
class_name PreparationStation

## La mesa recibe los cuatro ingredientes de la receta en cualquier orden.
## Al completarla aparece un encebollado arrastrable para el despacho.
@export var recipe: RecipeData = preload("res://resources/recipes/encebollado.tres")
@export var result_scene: PackedScene = preload("res://src/entities/item/base_item.tscn")

var _ingredientes: Array[ItemData] = []
var _producto_actual: BaseItem = null

@onready var ingredientes_en_mesa: Node2D = $IngredientesEnMesa

## BaseItem consulta esto para indicar si el drop en la mesa será aceptado.
func can_receive_ingredient(item: ItemData) -> bool:
	if item == null or recipe == null or recipe.final_product == null:
		return false
	if is_instance_valid(_producto_actual):
		return false
	var requerido := false
	for ingrediente in recipe.require_ingredients:
		if _misma_identidad(ingrediente, item):
			requerido = true
			break
	if not requerido:
		return false
	for ingrediente in _ingredientes:
		if _misma_identidad(ingrediente, item):
			return false
	return true

## Consume un ingrediente válido soltado en AssemblyArea; cada tipo cuenta una vez.
func recibir_ingrediente(item: ItemData) -> bool:
	if not can_receive_ingredient(item):
		return false
	_ingredientes.append(item)
	if OrderData.key_of_contents(_ingredientes) == OrderData.key_of_contents(recipe.require_ingredients):
		if not _crear_encebollado():
			_ingredientes.pop_back()
			return false
		_ingredientes.clear()
	_dibujar_ingredientes()
	return true

func _misma_identidad(a: ItemData, b: ItemData) -> bool:
	if a == null or b == null:
		return false
	if a.item_id != "" and b.item_id != "":
		return a.item_id == b.item_id
	return a.resource_path == b.resource_path

## Los ingredientes pendientes quedan visibles en la mesa sin necesitar plato.
func _dibujar_ingredientes() -> void:
	for hijo in ingredientes_en_mesa.get_children():
		ingredientes_en_mesa.remove_child(hijo)
		hijo.queue_free()
	var cantidad := _ingredientes.size()
	for indice in range(cantidad):
		var textura := _ingredientes[indice].icon
		if textura == null:
			continue
		var icono := Sprite2D.new()
		icono.texture = textura
		icono.scale = Vector2.ONE * (90.0 / maxf(textura.get_size().x, textura.get_size().y))
		icono.position = Vector2((indice - (cantidad - 1) * 0.5) * 110.0, 0.0)
		ingredientes_en_mesa.add_child(icono)

func _crear_encebollado() -> bool:
	if result_scene == null:
		return false
	var producto := result_scene.instantiate() as BaseItem
	if producto == null:
		push_error("PreparationStation.result_scene debe heredar de BaseItem.")
		return false
	producto.data = recipe.final_product
	producto.position = ingredientes_en_mesa.position
	# Agranda solo el resultado de esta mesa, incluido su área para arrastrarlo.
	producto.scale = Vector2.ONE * 2.0
	add_child(producto)
	_producto_actual = producto
	return true
