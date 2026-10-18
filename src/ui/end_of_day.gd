extends CanvasLayer

## Panel de fin de día. Muestra el resumen de la liquidación que
## `GameManager.end_day()` deja en `last_settlement` (ganado, renta, saldo o
## deuda). Se muestra con el juego en pausa; el botón vuelve al menú principal.

@onready var resumen: Label = $Fondo/Centro/Panel/Margin/VBox/Resumen
@onready var boton: Button = $Fondo/Centro/Panel/Margin/VBox/Boton


func _ready() -> void:
	var game_manager := get_node_or_null("/root/GameManager")
	var datos: Dictionary = game_manager.get("last_settlement") if game_manager != null else {}
	var ganado := int(datos.get("earnings", 0))
	var renta := int(datos.get("rent", 0))
	var saldo := int(datos.get("balance", 0))
	var deuda := int(datos.get("debt", 0))
	var texto := "Ganado hoy: $%d\nRenta: -$%d\nSaldo: $%d" % [ganado, renta, saldo]
	if deuda > 0:
		texto += "\n\n¡No alcanzó para la renta!\nDeuda: $%d" % deuda
	resumen.text = texto
	boton.pressed.connect(_on_boton_pressed)


func _on_boton_pressed() -> void:
	queue_free()
	var game_manager := get_node_or_null("/root/GameManager")
	if game_manager != null:
		game_manager.call("go_to_menu")
