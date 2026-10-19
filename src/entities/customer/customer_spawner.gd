extends Node2D
## Spawns customers in a compact horizontal row relative to this node.
class_name CustomerSpawner

## Emitted after a customer has been added to the row and connected to its lifecycle signals.
signal customer_spawned(customer: CustomerBase)

## Emitted when the active customer list changes (spawn or departure). The HUD
## uses this to rebuild the order cards panel.
signal customers_changed(customers: Array)

## Scene to instantiate; its root must inherit from CustomerBase.
@export var customer_scene: PackedScene
## Pool de arquetipos de cliente. Se selecciona uno al azar en cada spawn.
## Si el pool está vacío se usa el customer_data que traiga la escena base.
@export var customer_data_pool: Array[CustomerData] = []
## Optional generator; when assigned, each spawned customer receives a
## random OrderData before entering the tree (so its HUD shows the order).
@export var order_generator: OrderGenerator
## Maximum number of active customers; the hard limit is three.
@export_range(1, 3, 1) var max_customers: int = 3
## Time between automatic spawn attempts, in seconds.
@export_range(0.1, 60.0, 0.1) var spawn_interval: float = 5.0
## Horizontal distance between customer origins, in this node's local coordinates.
@export_range(0.0, 1024.0, 1.0) var customer_spacing: float = 250.0
## If enabled, starts spawning as soon as this node enters the scene tree.
@export var spawn_on_ready: bool = true

## Currently active customers in row order.
var active_customers: Array[CustomerBase] = []
var spawn_timer: Timer


## Creates the timer and optionally spawns the first customer immediately.
func _ready() -> void:
	# El ritmo de clientes se centraliza en RunBalance; los exports quedan como
	# respaldo si el recurso no está disponible (p. ej. arranques headless).
	var balance := _balance()
	if balance != null:
		max_customers = balance.max_customers
		spawn_interval = balance.spawn_interval

	spawn_timer = Timer.new()
	spawn_timer.wait_time = maxf(spawn_interval, 0.1)
	spawn_timer.timeout.connect(spawn_customer)
	add_child(spawn_timer)
	if spawn_on_ready:
		spawn_customer()
		spawn_timer.start()


## Autoload GameManager. Se resuelve por ruta en vez del identificador global
## para que el script compile también en arranques headless con `--script`.
func _game_manager() -> Node:
	return get_node_or_null("/root/GameManager")


## RunBalance del autoload GameManager, o null si no está disponible.
func _balance() -> RunBalance:
	var game_manager := _game_manager()
	if game_manager == null:
		return null
	return game_manager.get("balance") as RunBalance


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
	# Asignar CustomerData desde el pool (aleatorio) antes de add_child.
	# Si el pool está vacío se respeta el customer_data que traiga la escena.
	if not customer_data_pool.is_empty():
		customer.customer_data = customer_data_pool[randi() % customer_data_pool.size()]
	if order_generator != null:
		# Asignado antes de add_child para que _ready pinte el pedido.
		customer.order = order_generator.generate()
	add_child(customer)
	active_customers.append(customer)
	customer.finished.connect(_on_customer_finished)
	customer.tree_exited.connect(_on_customer_tree_exited.bind(customer))
	customer.served.connect(_on_customer_served)
	customer.patience_expired.connect(_on_customer_patience_expired)
	customer_spawned.emit(customer)
	customers_changed.emit(active_customers.duplicate())
	return customer


## Aviso flotante cuando un cliente se queda sin paciencia y se marcha.
func _on_customer_patience_expired(customer: CustomerBase) -> void:
	FloatingText.spawn(self, customer.position + Vector2(0.0, -150.0) \
		, "¡Se fue!", Color(0.96, 0.45, 0.4), 20)


## Removes a served or expired customer and closes the gap in the row.
func _on_customer_finished(customer: CustomerBase) -> void:
	active_customers.erase(customer)
	_arrange_customers()
	customer.queue_free()


## Paga al jugador cuando un cliente queda satisfecho.
## El pago base es el valor del pedido (OrderData.price, precio por ítem) o,
## en modo clásico sin pedido, CustomerData.reward.
## El pago escalonado depende del ratio de paciencia en el momento de ser servido:
##   > 0.66  → 100 % del pago (cliente recién esperando)
##   > 0.33  →  80 % del pago (llegando a la mitad)
##   <= 0.33 →  50 % del pago (a punto de irse)
## Encima se aplica tip_percent como porcentaje adicional fijo del arquetipo.
func _on_customer_served(customer: CustomerBase) -> void:
	if customer.customer_data == null:
		return
	var base_value: int = customer.order.price() if customer.order != null \
		else customer.customer_data.reward
	var tip: int = int(base_value * customer.customer_data.tip_percent / 100.0)
	var total: int = base_value + tip

	var ratio := customer.patience_ratio_at_serve
	var multiplier: float
	if ratio > 0.66:
		multiplier = 1.0    # tramo 1: paciencia alta → pago completo
	elif ratio > 0.33:
		multiplier = 0.8    # tramo 2: paciencia media → 80 %
	else:
		multiplier = 0.5    # tramo 3: paciencia baja → 50 %

	var gm := _game_manager()
	if gm != null:
		var pago: int = int(total * multiplier)
		gm.call("add_money", pago)
		# Feedback flotante del pago sobre el cliente atendido.
		FloatingText.spawn(self, customer.position + Vector2(0.0, -150.0) \
			, "+$%d" % pago, Color(0.6, 0.95, 0.65), 22)


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
	customers_changed.emit(active_customers.duplicate())
