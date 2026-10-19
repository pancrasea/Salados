extends Area2D

@onready var waiting: AnimatedSprite2D = $Waiting
@onready var called: Sprite2D = $Called
@onready var running: Sprite2D = $Running

const REFILL_MENU = preload("res://src/ui/MenuRefill.tscn")
var menu_node: Node = null

var tween : Tween

func _ready() -> void:
	GameEvents.call_refill_item.connect(_on_call_item_refill)

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			waiting.visible = false
			called.visible = true
			running.visible = false
			if waiting.visible: _animate_milo()
			mostrar_componente()

func _animate_milo():
	if tween and tween.is_valid():
		tween.kill()
	
	tween = get_tree().create_tween()

	var last_scale = called.scale

	tween.tween_property(called, "scale:y", last_scale.y + 0.4, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(called, "scale:y", last_scale.y, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func mostrar_componente():
	var station := get_parent() as BackStation
	if station == null or not station.can_refill():
		return
	print("MENU ACTIVO")
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


func _on_call_item_refill():
	waiting.visible = false
	called.visible = false
	running.visible = true

	var timer =  get_tree().create_timer(0.5)
	await timer.timeout

	waiting.visible = false
	called.visible = false
	running.visible = false

	timer =  get_tree().create_timer(4.5)
	await timer.timeout

	waiting.visible = true
	called.visible = false
	running.visible = false
