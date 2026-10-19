extends PanelContainer
## Tarjeta de pedido para el HUD.
## Muestra la orden de un cliente: número de orden, icono del plato base,
## badges de extras, barra de paciencia y precio.
## Se actualiza via `setup(customer, index)` cada vez que el spawner cambia
## la lista activa, y con la señal `patience_changed` del propio cliente.

## Referencia al cliente que representa esta tarjeta.
var _customer: CustomerBase = null

## ─── Nodos internos (asignados en _ready por ruta) ───
@onready var order_number_label: Label = $VBox/OrderNumber
@onready var order_icon: TextureRect = $VBox/OrderRow/OrderIcon
@onready var order_placeholder: Label = $VBox/OrderRow/OrderPlaceholder
@onready var extras_row: HBoxContainer = $VBox/ExtrasRow
@onready var patience_bar: ProgressBar = $VBox/PatienceBar
@onready var price_label: Label = $VBox/PriceLabel

var _patience_style: StyleBoxFlat = null


func _ready() -> void:
	# Duplicar el estilo del fill para poder mutar su color individualmente.
	_patience_style = patience_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	patience_bar.add_theme_stylebox_override("fill", _patience_style)


## Vincula esta tarjeta a un cliente y le asigna su posición en la fila (1-based).
## Desconecta señales del cliente anterior si las había.
func setup(customer: CustomerBase, index: int) -> void:
	_disconnect_previous()
	_customer = customer
	order_number_label.text = "#%d" % (index + 1)

	# ── Icono base ──────────────────────────────────────────────────────────
	var base: ItemData = null
	if customer.order != null:
		base = customer.order.base
	elif customer.customer_data != null:
		base = customer.customer_data.requested_item

	if base != null and base.icon != null:
		order_icon.texture = base.icon
		order_icon.show()
		order_placeholder.hide()
	else:
		order_icon.texture = null
		order_icon.hide()
		order_placeholder.show()

	# ── Extras ──────────────────────────────────────────────────────────────
	_rebuild_extras(customer.order.extras if customer.order != null else [])

	# ── Precio ──────────────────────────────────────────────────────────────
	if customer.order != null:
		price_label.text = "$%d" % customer.order.price()
		price_label.show()
	else:
		price_label.hide()

	# ── Paciencia ────────────────────────────────────────────────────────────
	patience_bar.max_value = maxf(customer.patience_max, 0.1)
	patience_bar.value = customer.patience_remaining
	_update_patience_color(customer.patience_remaining / maxf(customer.patience_max, 0.1))

	# Conectar señal de paciencia del cliente para actualizar la barra en tiempo real.
	if not customer.patience_changed.is_connected(_on_patience_changed):
		customer.patience_changed.connect(_on_patience_changed)


## Desconecta las señales del cliente anterior para evitar callbacks huérfanos.
func _disconnect_previous() -> void:
	if _customer == null or not is_instance_valid(_customer):
		return
	if _customer.patience_changed.is_connected(_on_patience_changed):
		_customer.patience_changed.disconnect(_on_patience_changed)


## Reconstruye los badges de extras. Acepta Array sin tipado para pasar [] literal.
func _rebuild_extras(extras: Array) -> void:
	for child in extras_row.get_children():
		child.queue_free()
	for extra: ItemData in extras:
		if extra == null:
			continue
		if extra.icon != null:
			var rect := TextureRect.new()
			rect.texture = extra.icon
			rect.custom_minimum_size = Vector2(20.0, 20.0)
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			extras_row.add_child(rect)
		else:
			var label := Label.new()
			var fallback := extra.name if extra.name != "" else extra.item_id
			label.text = fallback.substr(0, 1).to_upper() if fallback != "" else "?"
			label.add_theme_font_size_override("font_size", 13)
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			extras_row.add_child(label)
	# Ocultar la fila si no hay extras para no ocupar espacio.
	extras_row.visible = extras_row.get_child_count() > 0


## Actualiza la barra de paciencia y su color según el ratio restante.
func _on_patience_changed(_customer_ref: CustomerBase, remaining: float) -> void:
	patience_bar.value = remaining
	var ratio := remaining / maxf(patience_bar.max_value, 0.1)
	_update_patience_color(ratio)


func _update_patience_color(ratio: float) -> void:
	if _patience_style == null:
		return
	if ratio > 0.6:
		_patience_style.bg_color = Color("#57b66f")
	elif ratio > 0.3:
		_patience_style.bg_color = Color("#e5ae4b")
	else:
		_patience_style.bg_color = Color("#df5b52")


func _exit_tree() -> void:
	_disconnect_previous()
