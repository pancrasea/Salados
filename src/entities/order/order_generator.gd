class_name OrderGenerator extends Node

## Genera pedidos aleatorios (OrderData) para asignar a clientes recién
## creados. Usado por CustomerSpawner; también se puede invocar generate()
## manualmente desde cualquier script.

## Plato base de los pedidos compuestos (ej. encebollado).
@export var base_item: ItemData
## Productos que pueden pedirse solos, sin plato base ni extras.
@export var standalone_pool: Array[ItemData] = []
## Probabilidad de generar un pedido individual cuando hay productos configurados.
@export_range(0.0, 1.0, 0.05) var standalone_chance: float = 0.25
## Pool de agregados posibles para el encebollado.
@export var extras_pool: Array[ItemData] = []
## Cantidad máxima de agregados por pedido.
@export_range(0, 5, 1) var max_extras: int = 3
## Cantidad mínima de agregados por pedido.
@export_range(0, 5, 1) var min_extras: int = 0


## Devuelve un producto individual o el plato base con extras sin repetición.
## Si no hay pool de individuales, conserva el flujo anterior.
func generate() -> OrderData:
	var order := OrderData.new()
	if not standalone_pool.is_empty() and randf() < standalone_chance:
		order.base = standalone_pool.pick_random()
		return order
	order.base = base_item
	if extras_pool.is_empty() or max_extras <= 0:
		return order

	var pool := extras_pool.duplicate()
	pool.shuffle()
	var count := randi_range(mini(min_extras, max_extras), max_extras)
	for index in mini(count, pool.size()):
		order.extras.append(pool[index])
	return order
