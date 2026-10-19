extends Area2D
const REFILL_MENU = preload("res://src/ui/MenuRefill.tscn")
var menu_node: Node = null
 
func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("MENU ACTIVO")
			mostrar_componente()

func mostrar_componente():
	if not is_instance_valid(menu_node):
		menu_node = REFILL_MENU.instantiate()
		get_tree().current_scene.add_child(menu_node)
		print("Menú instanciado: ", menu_node.get_path())
	
	menu_node.show()
	var panel = menu_node.get_node("Panel")
	panel.show()
	
	print("Panel visible: ", panel.is_visible_in_tree())
	print("Posición: ", panel.global_position)
	print("Tamaño: ", panel.size)
