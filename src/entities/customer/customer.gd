extends Node2D
class_name CustomerBase

## Base customer behavior; extend this class or attach additional child nodes to specialize it.

## Emitted when the customer's selectable state changes.
signal selected_changed(customer: CustomerBase, selected: bool)
## Emitted whenever patience decreases; remaining time is expressed in seconds.
signal patience_changed(customer: CustomerBase, remaining: float)
## Emitted once when patience reaches zero.
signal patience_expired(customer: CustomerBase)
## Emitted when the selected customer receives an item other than the requested definition.
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

## Current lifecycle state; only WAITING customers accept interaction.
var state: State = State.WAITING
## Remaining patience in seconds.
var patience_remaining: float = 0.0
## Whether the player currently has this customer selected.
var is_selected: bool = false

@onready var selection_area: Area2D = $SelectionArea
@onready var patience_bar: ProgressBar = $PatienceBar
@onready var order_icon_frame: Panel = $OrderIconFrame
@onready var order_icon: TextureRect = $OrderIconFrame/OrderIcon
@onready var order_placeholder: Label = $OrderIconFrame/OrderPlaceholder

var patience_fill_style: StyleBoxFlat


## Initializes patience and connects the scene's selection area.
func _ready() -> void:
	# Each instance needs its own fill style because its patience color changes over time.
	patience_fill_style = patience_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	patience_bar.add_theme_stylebox_override("fill", patience_fill_style)

	if customer_data != null:
		patience_remaining = maxf(customer_data.patience_seconds, 0.0)
		patience_bar.max_value = maxf(customer_data.patience_seconds, 0.1)
	else:
		patience_bar.hide()

	_update_order_display()
	if customer_data != null:
		_update_patience_display()
	selection_area.input_event.connect(_on_selection_area_input_event)


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


## Shows the request texture, or a question-mark placeholder until a request is configured.
func _update_order_display() -> void:
	order_icon_frame.visible = customer_data != null
	if customer_data == null:
		return

	var has_request := customer_data.requested_item != null
	order_icon.texture = customer_data.requested_item.icon if has_request else null
	order_icon.visible = order_icon.texture != null
	order_placeholder.visible = order_icon.texture == null


## Keeps the patience bar value and warning color synchronized with remaining time.
func _update_patience_display() -> void:
	patience_bar.value = patience_remaining
	var patience_ratio := patience_remaining / patience_bar.max_value
	if patience_ratio > 0.6:
		patience_fill_style.bg_color = Color("#57b66f")
	elif patience_ratio > 0.3:
		patience_fill_style.bg_color = Color("#e5ae4b")
	else:
		patience_fill_style.bg_color = Color("#df5b52")


## Selects only customers who are still waiting.
func set_selected(selected: bool) -> void:
	var next_selected := selected and state == State.WAITING
	if is_selected == next_selected:
		return
	is_selected = next_selected
	selected_changed.emit(self, is_selected)


## Accepts only the exact requested item definition while this customer is selected.
## Returns true when the customer is served, otherwise false.
func receive_item(item: ItemData) -> bool:
	if state != State.WAITING or not is_selected or customer_data == null:
		return false
	if customer_data.requested_item == null:
		return false
	if item != customer_data.requested_item:
		item_rejected.emit(self, item)
		return false

	state = State.SERVED
	set_selected(false)
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
