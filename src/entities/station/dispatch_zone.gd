class_name DispatchZone extends Node2D

## Zona de despacho de la sección de preparación: al soltar aquí un plato
## terminado (ItemData.is_final_product), lo transfiere a la bandeja de la
## estación destino (por defecto la principal, con clientes) para que allí se
## le agreguen los extras. Se detecta en BaseItem._verify_target_and_drop por
## el Area2D hijo, igual que TrashBin y los clientes.
##
## El plato terminado no depende de que la estación destino esté visible: la
## bandeja recibe el contenido aunque esté oculta, y lo muestra al volver.

## Lado de GameManager cuya bandeja recibe el plato (0 = FRONT/clientes).
## Se usa int para no acoplar el recurso al autoload en tiempo de export.
@export var target_side: int = 0
## Nombre preferido del nodo receptor dentro de la estación destino.
@export var receiver_name: String = "Bandeja"


## Intenta despachar `item`. Solo acepta platos terminados (is_final_product);
## devuelve true si encontró receptor y transfirió el contenido.
func dispatch(item: BaseItem) -> bool:
	if item == null or item.data == null or not item.data.is_final_product:
		return false
	var receiver := _find_receiver()
	if receiver == null:
		push_warning("DispatchZone: no hay bandeja receptora en la estación %d." % target_side)
		return false
	receiver.collect_ingredients(item.data)
	item.queue_free()
	return true


## Busca la bandeja receptora: primero por nombre dentro de la estación
## destino y, si no existe, el primer contenedor reutilizable que encuentre.
func _find_receiver() -> BaseItem:
	var game_manager := _game_manager()
	if game_manager == null:
		return null
	var station := game_manager.get_station(target_side) as Station
	if station == null:
		return null
	var named := station.get_node_or_null(receiver_name)
	if _is_receiver(named):
		return named
	return _first_receiver(station)


## Autoload de navegación. Se resuelve por ruta en vez del identificador
## global para que el script también compile en arranques headless con
## `--script`, donde los autoloads no se registran como globales.
func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")


## Un receptor válido es un contenedor reutilizable (no producto final).
func _is_receiver(node: Node) -> bool:
	var item := node as BaseItem
	return item != null and item.data != null \
		and item.data.is_container and not item.data.is_final_product


func _first_receiver(node: Node) -> BaseItem:
	for child in node.get_children():
		if _is_receiver(child):
			return child
		var found := _first_receiver(child)
		if found != null:
			return found
	return null
