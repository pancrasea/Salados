extends Node2D
class_name CustomerBase

## Base customer behavior; extend this class or attach additional child nodes to specialize it.

## Emitted when the customer's selectable state changes.
signal selected_changed(customer: CustomerBase, selected: bool)
## Emitted whenever patience decreases; remaining time is expressed in seconds.
signal patience_changed(customer: CustomerBase, remaining: float)
## Emitted once when patience reaches zero.
signal patience_expired(customer: CustomerBase)
## Emitted when a waiting customer receives an item other than the requested definition.
signal item_rejected(customer: CustomerBase, item: ItemData)
## Emitted after the requested item definition is accepted.
signal item_received(customer: CustomerBase, item: ItemData)
## Emitted when the customer is served successfully.
signal served(customer: CustomerBase)
## Emitted when the customer leaves or is served and can be removed from the scene.
signal finished(customer: CustomerBase)

## Lifecycle states that control whether the customer can be selected or served.
enum State { WAITING, SERVED, LEFT }

## Configuration resource containing this customer's order and patience settings.
@export var customer_data: CustomerData

## Pedido estructurado (plato base + agregados). Tiene prioridad sobre
## CustomerData.requested_item; si es null se usa el modo clásico por ítem.
## Lo asigna CustomerSpawner con un OrderGenerator antes de add_child.
@export var order: OrderData

## Current lifecycle state; only WAITING customers accept interaction.
var state: State = State.WAITING
## Remaining patience in seconds.
var patience_remaining: float = 0.0
## Whether the player currently has this customer selected.
var is_selected: bool = false
## Ratio de paciencia (0.0–1.0) en el momento en que fue atendido.
## Solo válido después de que served se emita; usado para calcular el pago.
var patience_ratio_at_serve: float = 1.0

@onready var selection_area: Area2D = $SelectionArea
@onready var patience_bar: ProgressBar = $PatienceBar
@onready var order_icon_frame: Panel = $OrderIconFrame
@onready var order_icon: TextureRect = $OrderIconFrame/OrderIcon
@onready var order_placeholder: Label = $OrderIconFrame/OrderPlaceholder

## Fila de badges con los agregados del pedido (opción "icono base + badges");
## se crea en runtime porque la escena no la define.
@onready var order_extras_row: HBoxContainer = _create_order_extras_row()

## Etiqueta con el precio del pedido, sobre el marco del icono. Se crea en
## runtime porque la escena no la define.
@onready var order_price_label: Label = _create_order_price_label()

var patience_fill_style: StyleBoxFlat


## Initializes patience and connects the scene's selection area.
func _ready() -> void:
	# Each instance needs its own fill style because its patience color changes over time.
	patience_fill_style = patience_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	patience_bar.add_theme_stylebox_override("fill", patience_fill_style)

	if customer_data != null:
		var patience := _patience_for(customer_data)
		patience_remaining = maxf(patience, 0.0)
		patience_bar.max_value = maxf(patience, 0.1)
		# Aplicar textura del arquetipo si está definida en el CustomerData.
		if customer_data.texture != null:
			var visual := get_node_or_null("Visual") as Sprite2D
			if visual != null:
				visual.texture = customer_data.texture
				if customer_data.scale != null:
					visual.scale = customer_data.scale
			
	else:
		patience_bar.hide()

	_update_order_display()
	if customer_data != null:
		_update_patience_display()
	selection_area.input_event.connect(_on_selection_area_input_event)


## Paciencia efectiva: la del arquetipo si la define (> 0); si no, la central
## de `RunBalance.default_patience`. 30 s como último respaldo.
func _patience_for(data: CustomerData) -> float:
	if data.patience_seconds > 0.0:
		return data.patience_seconds
	var game_manager := get_node_or_null("/root/GameManager")
	if game_manager != null:
		var balance: RunBalance = game_manager.get("balance")
		if balance != null:
			return balance.default_patience
	return 30.0


## Counts down patience while waiting and emits the leave signals at zero.
func _process(delta: float) -> void:
	if state != State.WAITING or customer_data == null:
		return

	var previous_patience := patience_remaining
	patience_remaining = maxf(patience_remaining - delta, 0.0)
	if patience_remaining != previous_patience:
		_update_patience_display()
		patience_changed.emit(self, patience_remaining)
	if patience_remaining == 0.0:
		state = State.LEFT
		set_selected(false)
		patience_expired.emit(self)
		finished.emit(self)


## Shows the request texture plus the extras badges, or a question-mark
## placeholder until a request is configured.
func _update_order_display() -> void:
	var has_order := order != null
	var has_request := customer_data != null and customer_data.requested_item != null
	order_icon_frame.visible = has_order or has_request
	if not order_icon_frame.visible:
		_rebuild_extras_row([])
		order_price_label.visible = false
		return

	var base: ItemData = order.base if has_order else customer_data.requested_item
	order_icon.texture = base.icon if base != null else null
	order_icon.visible = order_icon.texture != null
	order_placeholder.visible = order_icon.texture == null
	_rebuild_extras_row(order.extras if has_order else [])
	# Precio solo para pedidos estructurados (plato base + extras).
	order_price_label.visible = has_order
	if has_order:
		order_price_label.text = "$%d" % order.price()


## Creates the horizontal container that holds the extras badges, placed
## right above the order frame.
func _create_order_extras_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "OrderExtrasRow"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	row.position = Vector2(-40.0, -146.0)
	return row


## Creates the small price label shown above the extras row (over the order
## frame). Adds an outline so it stays readable over any background.
func _create_order_price_label() -> Label:
	var label := Label.new()
	label.name = "OrderPriceLabel"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.95, 0.86, 0.62))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	label.add_theme_constant_override("outline_size", 4)
	add_child(label)
	label.position = Vector2(-40.0, -172.0)
	label.custom_minimum_size = Vector2(80.0, 22.0)
	return label


## Rebuilds the extras badges row. Each extra shows its icon, or its first
## letter as fallback when no texture is assigned (useful during prototyping).
## Se acepta Array sin parametrizar para poder pasar el literal [] vacío.
func _rebuild_extras_row(extras: Array) -> void:
	for child in order_extras_row.get_children():
		child.queue_free()
	for extra: ItemData in extras:
		if extra == null:
			continue
		if extra.icon != null:
			var rect := TextureRect.new()
			rect.texture = extra.icon
			rect.custom_minimum_size = Vector2(14.0, 14.0)
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			order_extras_row.add_child(rect)
		else:
			var label := Label.new()
			var fallback := extra.name if extra.name != "" else extra.item_id
			label.text = fallback.substr(0, 1).to_upper() if fallback != "" else "?"
			label.add_theme_font_size_override("font_size", 12)
			order_extras_row.add_child(label)


## Keeps the patience bar value and warning color synchronized with remaining time.
func _update_patience_display() -> void:
	patience_bar.value = patience_remaining
	var patience_ratio := patience_remaining / patience_bar.max_value
	if patience_ratio > 0.6:
		patience_fill_style.bg_color = Color("#57b66f")
	elif patience_ratio > 0.3:
		patience_fill_style.bg_color = Color("#e5ae4b")
	else:
		if customer_data.texture_alt != null:
			var visual := get_node_or_null("Visual") as Sprite2D
			if visual != null:
				visual.texture = customer_data.texture_alt
		patience_fill_style.bg_color = Color("#df5b52")


## Selects only customers who are still waiting.
func set_selected(selected: bool) -> void:
	var next_selected := selected and state == State.WAITING
	if is_selected == next_selected:
		return
	is_selected = next_selected
	selected_changed.emit(self, is_selected)


## Accepts an item while this customer is still waiting; selection is NOT
## required, any customer in the row can receive its order. With a
## structured order it compares canonical keys (ItemData.recipe_key vs
## OrderData.key); otherwise it falls back to the legacy exact-reference
## check against CustomerData.requested_item.
## Returns true when the customer is served, otherwise false.
func receive_item(item: ItemData) -> bool:
	if state != State.WAITING or customer_data == null:
		return false
	if order != null:
		if not order.matches(item):
			item_rejected.emit(self, item)
			return false
	else:
		if customer_data.requested_item == null:
			return false
		if item != customer_data.requested_item:
			item_rejected.emit(self, item)
			return false

	state = State.SERVED
	set_selected(false)
	# Guardar el ratio de paciencia para el cálculo del pago escalonado.
	patience_ratio_at_serve = patience_remaining / maxf(patience_bar.max_value, 0.1)
	item_received.emit(self, item)
	served.emit(self)
	finished.emit(self)
	return true


## Toggles selection on a left-click inside the customer collision shape.
func _on_selection_area_input_event(
	_viewport: Viewport,
	event: InputEvent,
	_shape_idx: int
) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		set_selected(not is_selected)
