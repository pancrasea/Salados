class_name DispatchZone extends Node2D

## Zona de despacho: al soltar un producto final, crea un ítem arrastrable en
## DraggableZone de la estación destino. Se detecta en BaseItem por el Area2D
## hijo, igual que TrashBin y los clientes.
##
## El destino puede estar oculto: el plato aparece al volver a esa estación.

## Lado de GameManager cuya área recibe el plato (0 = FRONT/clientes).
## Se usa int para no acoplar el recurso al autoload en tiempo de export.
@export var target_side: int = 0
## Nombre del área receptora dentro de la estación destino.
@export var receiver_name: String = "DraggableZone"


## Intenta despachar `item`. Solo acepta platos terminados (is_final_product);
## devuelve true si el área pudo crear una copia arrastrable del producto.
func dispatch(item: BaseItem) -> bool:
	if item == null or item.data == null or not item.data.is_final_product:
		return false
	var receiver := _find_receiver()
	if receiver == null:
		push_warning("DispatchZone: no hay DraggableZone en la estación %d." % target_side)
		return false
	if not receiver.receive(item.data):
		return false
	item.queue_free()
	return true


## Busca el área de espera por nombre dentro de la estación destino.
func _find_receiver() -> DraggableZone:
	var game_manager := _game_manager()
	if game_manager == null:
		return null
	var station := game_manager.get_station(target_side) as Station
	if station == null:
		return null
	return station.get_node_or_null(receiver_name) as DraggableZone


## Autoload de navegación. Se resuelve por ruta en vez del identificador
## global para que el script también compile en arranques headless con
## `--script`, donde los autoloads no se registran como globales.
func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")
