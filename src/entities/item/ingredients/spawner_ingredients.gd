class_name SpawnerIngredients extends Node2D

@export var item_data: ItemData
@export var item_scene: PackedScene

var current_stock: int = 0
var current_item: BaseItem = null

func _ready() -> void:
	if item_data:
		current_stock = item_data.max_quantity
		_try_generate_item()

func _process(delta: float) -> void:
	if current_item == null and current_stock > 0:
		_try_generate_item()
		print("generando item")

func _try_generate_item():
	if current_stock <= 0:
		return
	
	var new_item = item_scene.instantiate() as BaseItem
	new_item.data = item_data
	
	get_parent().call_deferred("add_child",new_item)
	new_item.set_deferred("global_position", global_position)
	
	current_item = new_item
	current_stock -= 1
	
	new_item.tree_exited.connect(_on_remove_item)

func _on_remove_item():
	current_item = null

func replenish_stock():
	if item_data:
		current_stock - item_data.max_quantity
		
		if current_item == null:
			_try_generate_item()
		
	
