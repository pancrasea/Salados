class_name TrashBin extends Node2D

## Tacho de basura: punto de descarte para pedidos preparados que salieron
## mal. Se detecta en BaseItem._verify_target_and_drop() por el Area2D hijo,
## igual que los clientes y los contenedores.

@onready var open_trash: Sprite2D = $OpenTrash
@onready var close_trash: Sprite2D = $CloseTrash
@onready var drop_area: Area2D = $Area2D

func _ready() -> void:
	_set_open(false)

## El sprite abierto solo aparece mientras un BaseItem arrastrado se solapa
## con el área que también acepta el descarte al soltarlo.
func _process(_delta: float) -> void:
	var dragged := BaseItem.current_item_dragging
	var should_open := false
	if is_visible_in_tree() and is_instance_valid(dragged) and dragged.is_dragging:
		var item_area := dragged.get_node_or_null("Area2D") as Area2D
		should_open = item_area != null and drop_area.overlaps_area(item_area)
	_set_open(should_open)

func _set_open(is_open: bool) -> void:
	open_trash.visible = is_open
	close_trash.visible = not is_open


## Descarta el ítem soltado sobre el tacho. La bandeja (contenedor) se
## vacía y vuelve a su posición inicial; un alimento suelto se consume.
## Devuelve true si el drop fue atendido, para que BaseItem no reponga el
## ítem en su sitio.
func discard(item: BaseItem) -> bool:
	if item == null:
		return false
	_set_open(false)
	if item.data != null and item.data.is_container:
		item.reset_container()
	else:
		item.queue_free()
	return true
