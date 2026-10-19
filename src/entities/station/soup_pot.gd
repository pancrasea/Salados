class_name SoupPot extends Node2D

## Olla del líquido de la sopa (sección de preparación). Mantiene UN `BaseItem`
## de líquido arrastrable en su posición; cuando el jugador lo consume al
## soltarlo en la mesa de preparación (queue_free), repone otro tras `respawn_delay`.
##
## Nota: el ítem no se consume al levantarlo, solo al soltarlo en la mesa
## (ver BaseItem._verify_target_and_drop). Si el drop no encuentra destino, el
## ítem vuelve a su posición y la olla conserva su líquido.

## Emitida cada vez que aparece un líquido nuevo en la olla.
signal liquid_spawned(item: BaseItem)

## ItemData del líquido (ej. `resources/items/liquido_sopa.tres`).
@export var liquid_data: ItemData
## Escena instanciada por el líquido; su raíz debe heredar de BaseItem.
@export var item_scene: PackedScene
## Segundos antes de reponer el líquido consumido.
@export_range(0.0, 60.0, 0.1) var respawn_delay: float = 0.8
## Si está activo, genera el primer líquido al entrar en el árbol.
@export var spawn_on_ready: bool = true

var _item: BaseItem = null
var _timer: Timer


func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = maxf(respawn_delay, 0.05)
	_timer.timeout.connect(_on_respawn_timeout)
	add_child(_timer)
	if spawn_on_ready:
		refill()


## Genera un líquido si la olla está vacía; se puede invocar manualmente.
func refill() -> void:
	if is_instance_valid(_item) or liquid_data == null or item_scene == null:
		return
	var item := item_scene.instantiate() as BaseItem
	if item == null:
		push_error("SoupPot.item_scene debe heredar de BaseItem.")
		return
	item.data = liquid_data
	add_child(item)
	item.tree_exited.connect(_on_item_exited)
	_item = item
	liquid_spawned.emit(item)


func _on_item_exited() -> void:
	_item = null
	if is_inside_tree():
		_timer.start()


func _on_respawn_timeout() -> void:
	refill()
