class_name BaseItem extends Node2D

@export var data: ItemData

var is_dragging: bool = false
var collected_ingredients: Array[ItemData] = []
var initial_position: Vector2 = Vector2.ZERO
static var current_item_dragging: BaseItem = null

@onready var sprite_2d: Sprite2D = $Sprite2D


func _ready() -> void:
	if data:
		_update_visual()

func _update_visual():
	if sprite_2d:
		if data.icon:
			sprite_2d.texture = data.icon
		else:
			sprite_2d.texture = null

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
		
		# Caso contenedor (plato o vaso)
		if target is BaseItem and target.data and target.data.is_container:
			target.collect_ingredients(self.data)
			successful_drop = true
			
			break
		
		#TODO: Caso de las estaciones de trabajo
		
	if not successful_drop:
		global_position = initial_position

func collect_ingredients(new_ingredient: ItemData):
	if data and data.is_container and not data.is_final_product:
		collected_ingredients.append(new_ingredient)
		print(new_ingredient.name)
		#TODO: El manejo de las recetas
