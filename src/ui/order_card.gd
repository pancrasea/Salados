extends PanelContainer
## Tarjeta de pedido para el HUD.
## Muestra la orden de un cliente: número de orden, icono del plato base,
## badges de extras, barra de paciencia y precio.
## Se actualiza via `setup(customer, index)` después de add_child.

## Referencia al cliente que representa esta tarjeta.
var _customer: CustomerBase = null

## Nodos internos — se resuelven en setup() una vez el nodo ya está en el árbol.
var _order_number_label: Label = null
var _order_icon: TextureRect = null
var _order_placeholder: Label = null
var _extras_row: HBoxContainer = null
var _patience_bar: ProgressBar = null
var _price_label: Label = null
var _patience_style: StyleBoxFlat = null


## Vincula esta tarjeta a un cliente y le asigna su posición en la fila (1-based).
## Debe llamarse DESPUÉS de add_child para que los nodos estén disponibles.
func setup(customer: CustomerBase, index: int) -> void:
	_disconnect_previous()

	# Resolver nodos la primera vez (o si aún no se han resuelto).
	if _order_number_label == null:
		_order_number_label = $VBox/OrderNumber
		_order_icon        = $VBox/OrderRow/OrderIcon
		_order_placeholder = $VBox/OrderRow/OrderPlaceholder
		_extras_row        = $VBox/ExtrasRow
		_patience_bar      = $VBox/PatienceBar
		_price_label       = $VBox/PriceLabel
		# Duplicar estilo del fill para mutar color individualmente.
		_patience_style = _patience_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
		_patience_bar.add_theme_stylebox_override("fill", _patience_style)

	_customer = customer
	_order_number_label.text = "#%d" % (index + 1)

	# ── Icono base ──────────────────────────────────────────────────────────
	var base: ItemData = null
	if customer.order != null:
		base = customer.order.base
	elif customer.customer_data != null:
		base = customer.customer_data.requested_item

	if base != null and base.icon != null:
		_order_icon.texture = base.icon
		_order_icon.show()
		_order_placeholder.hide()
	else:
		_order_icon.texture = null
		_order_icon.hide()
		_order_placeholder.show()

	# ── Extras ──────────────────────────────────────────────────────────────
	_rebuild_extras(customer.order.extras if customer.order != null else [])

	# ── Precio ──────────────────────────────────────────────────────────────
	if customer.order != null:
		_price_label.text = "$%d" % customer.order.price()
		_price_label.show()
	else:
		_price_label.hide()

	# ── Paciencia ────────────────────────────────────────────────────────────
	_patience_bar.max_value = maxf(customer.patience_max, 0.1)
	_patience_bar.value = customer.patience_remaining
	_update_patience_color(customer.patience_remaining / maxf(customer.patience_max, 0.1))

	# Conectar señal de paciencia para actualizar la barra en tiempo real.
	if not customer.patience_changed.is_connected(_on_patience_changed):
		customer.patience_changed.connect(_on_patience_changed)


## Desconecta las señales del cliente anterior para evitar callbacks huérfanos.
func _disconnect_previous() -> void:
	if _customer == null or not is_instance_valid(_customer):
		return
	if _customer.patience_changed.is_connected(_on_patience_changed):
		_customer.patience_changed.disconnect(_on_patience_changed)


## Reconstruye los badges de extras.
func _rebuild_extras(extras: Array) -> void:
	for child in _extras_row.get_children():
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
			_extras_row.add_child(rect)
		else:
			var label := Label.new()
			var fallback := extra.name if extra.name != "" else extra.item_id
			label.text = fallback.substr(0, 1).to_upper() if fallback != "" else "?"
			label.add_theme_font_size_override("font_size", 13)
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_extras_row.add_child(label)
	_extras_row.visible = _extras_row.get_child_count() > 0


## Actualiza la barra de paciencia en tiempo real con la señal del cliente.
func _on_patience_changed(_customer_ref: CustomerBase, remaining: float) -> void:
	if _patience_bar == null:
		return
	_patience_bar.value = remaining
	_update_patience_color(remaining / maxf(_patience_bar.max_value, 0.1))


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
