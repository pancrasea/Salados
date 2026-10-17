extends Node2D
## Spawns customers in a compact horizontal row relative to this node.
class_name CustomerSpawner

## Emitted after a customer has been added to the row and connected to its lifecycle signals.
signal customer_spawned(customer: CustomerBase)

## Scene to instantiate; its root must inherit from CustomerBase.
@export var customer_scene: PackedScene
## Optional generator; when assigned, each spawned customer receives a
## random OrderData before entering the tree (so its HUD shows the order).
@export var order_generator: OrderGenerator
## Maximum number of active customers; the hard limit is three.
@export_range(1, 3, 1) var max_customers: int = 3
## Time between automatic spawn attempts, in seconds.
@export_range(0.1, 60.0, 0.1) var spawn_interval: float = 5.0
## Horizontal distance between customer origins, in this node's local coordinates.
@export_range(0.0, 1024.0, 1.0) var customer_spacing: float = 144.0
## If enabled, starts spawning as soon as this node enters the scene tree.
@export var spawn_on_ready: bool = true

## Currently active customers in row order.
var active_customers: Array[CustomerBase] = []
var spawn_timer: Timer


## Creates the timer and optionally spawns the first customer immediately.
func _ready() -> void:
	spawn_timer = Timer.new()
	spawn_timer.wait_time = maxf(spawn_interval, 0.1)
	spawn_timer.timeout.connect(spawn_customer)
	add_child(spawn_timer)
	if spawn_on_ready:
		spawn_customer()
		spawn_timer.start()


## Creates the next customer in the row, or returns null if spawning is unavailable.
## Call this directly to spawn on demand, regardless of the automatic timer setting.
func spawn_customer() -> CustomerBase:
	active_customers = active_customers.filter(
		func(customer: CustomerBase) -> bool: return is_instance_valid(customer)
	)
	if active_customers.size() >= clampi(max_customers, 1, 3):
		return null
	if customer_scene == null:
		push_warning("CustomerSpawner needs a customer_scene.")
		return null

	var customer := customer_scene.instantiate() as CustomerBase
	if customer == null:
		push_error("customer_scene must inherit from CustomerBase.")
		return null

	customer.position = Vector2(active_customers.size() * maxf(customer_spacing, 0.0), 0.0)
	if order_generator != null:
		# Asignado antes de add_child para que _ready pinte el pedido.
		customer.order = order_generator.generate()
	add_child(customer)
	active_customers.append(customer)
	customer.finished.connect(_on_customer_finished)
	customer.tree_exited.connect(_on_customer_tree_exited.bind(customer))
	customer_spawned.emit(customer)
	return customer


## Removes a served or expired customer and closes the gap in the row.
func _on_customer_finished(customer: CustomerBase) -> void:
	active_customers.erase(customer)
	_arrange_customers()
	customer.queue_free()


## Keeps the active list and row positions correct if a customer is freed externally.
func _on_customer_tree_exited(customer: CustomerBase) -> void:
	active_customers.erase(customer)
	_arrange_customers()


## Closes any gaps left when a customer leaves the row.
func _arrange_customers() -> void:
	var spacing := maxf(customer_spacing, 0.0)
	for index in active_customers.size():
		var customer := active_customers[index]
		if is_instance_valid(customer):
			customer.position = Vector2(index * spacing, 0.0)
