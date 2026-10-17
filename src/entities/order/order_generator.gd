class_name OrderGenerator extends Node

## Genera pedidos aleatorios (OrderData) para asignar a clientes recién
## creados. Usado por CustomerSpawner; también se puede invocar generate()
## manualmente desde cualquier script.

## Plato base de todos los pedidos generados (ej. encebollado).
@export var base_item: ItemData
## Pool de agregados posibles (pan, chifle, limón, canguil, maíz tostado).
@export var extras_pool: Array[ItemData] = []
## Cantidad máxima de agregados por pedido.
@export_range(0, 5, 1) var max_extras: int = 3
## Cantidad mínima de agregados por pedido.
@export_range(0, 5, 1) var min_extras: int = 0


## Devuelve un pedido nuevo con base_item y entre min_extras y max_extras
## agregados elegidos al azar sin repetición. Devuelve un pedido sin extras
## si no hay pool configurado.
func generate() -> OrderData:
	var order := OrderData.new()
	order.base = base_item
	if extras_pool.is_empty() or max_extras <= 0:
		return order

	var pool := extras_pool.duplicate()
	pool.shuffle()
	var count := randi_range(mini(min_extras, max_extras), max_extras)
	for index in mini(count, pool.size()):
		order.extras.append(pool[index])
	return order
