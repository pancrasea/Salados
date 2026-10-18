extends Control

const CEBOLLA: ItemData = preload("res://resources/items/item_cebolla_colorada.tres")
const YUCA: ItemData = preload("res://resources/items/item_yuca.tres")
const ALBACORA: ItemData = preload("res://resources/items/item_albacora.tres")
const NARANJA: ItemData = preload("res://resources/items/naranja.tres")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


func _on_onion_button_pressed() -> void:
	GameManager.refill_ing(CEBOLLA, 8)
	hide()
func _on_yuca_button_pressed() -> void:
	GameManager.refill_ing(YUCA, 8)
	hide()
	
func _on_fish_button_pressed() -> void:
	GameManager.refill_ing(ALBACORA, 8)
	hide()
func _on_orange_button_pressed() -> void:
	GameManager.refill_ing(NARANJA, 8)
	hide()
	
func _on_close_button_pressed() -> void:
	hide()
