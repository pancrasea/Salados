class_name TrashBin extends Node2D

## Tacho de basura: punto de descarte para pedidos preparados que salieron
## mal. Se detecta en BaseItem._verify_target_and_drop() por el Area2D hijo,
## igual que los clientes y los contenedores.


## Descarta el ítem soltado sobre el tacho. La bandeja (contenedor) se
## vacía y vuelve a su posición inicial; un alimento suelto se consume.
## Devuelve true si el drop fue atendido, para que BaseItem no reponga el
## ítem en su sitio.
func discard(item: BaseItem) -> bool:
	if item == null:
		return false
	if item.data != null and item.data.is_container:
		item.reset_container()
	else:
		item.queue_free()
	return true
