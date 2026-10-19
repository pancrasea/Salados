extends Control
class_name RefillMenu

const CEBOLLA: ItemData = preload("res://resources/items/item_cebolla_colorada.tres")
const YUCA: ItemData = preload("res://resources/items/item_yuca.tres")
const ALBACORA: ItemData = preload("res://resources/items/item_albacora.tres")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	
func _on_onion_button_pressed() -> void:
	if _begin_refill() == null:
		return
	GameEvents.call_refill_item.emit()
	GameManager.refill_ing(CEBOLLA, 8)
	hide()
func _on_yuca_button_pressed() -> void:
	if _begin_refill() == null:
		return
	GameEvents.call_refill_item.emit()
	GameManager.refill_ing(YUCA, 8)
	hide()
	
func _on_fish_button_pressed() -> void:
	if _begin_refill() == null:
		return
	GameEvents.call_refill_item.emit()
	GameManager.refill_ing(ALBACORA, 8)
	hide()
func _on_orange_button_pressed() -> void:
	var estacion := _begin_refill()
	if estacion == null:
		return
	GameEvents.call_refill_item.emit()
	estacion.refill_jugos()
	hide()
	
func _on_close_button_pressed() -> void:
	hide()

## Comparte el mismo cooldown entre ingredientes y jarra; null si aún espera.
func _begin_refill() -> BackStation:
	var estacion := GameManager.get_station(GameManager.Side.BACK) as BackStation
	if estacion == null or not estacion.try_start_refill():
		return null
	return estacion
