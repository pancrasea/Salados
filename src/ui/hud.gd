extends CanvasLayer

## HUD de juego: muestra el dinero actual, el tiempo restante del día y un
## panel de información de la sección visible. El panel cambia según la
## estación: precios de platos en la principal, stock de materia prima en la
## Sección 2 (corte/desmenuce) y stock de preparados en la Sección 3
## (preparación). Se instancia en main.tscn como hijo permanente y se
## muestra/oculta junto con la sesión de juego.

## Valores de GameManager.Side (FRONT, LEFT, RIGHT, BACK) repetidos como
## constantes locales para no depender del identificador global GameManager en
## arranques headless con `--script`.
const SIDE_FRONT: int = 0
const SIDE_LEFT: int = 1
const SIDE_RIGHT: int = 2

@onready var money_label: Label = $MoneyLabel
@onready var timer_label: Label = $TimerLabel
@onready var info_panel: PanelContainer = $InfoPanel
@onready var info_list: VBoxContainer = $InfoPanel/InfoList

## Autoload GameManager. Se resuelve por ruta en vez del identificador global
## para poder cargar el HUD en arranques headless con `--script`.
var _game_manager: Node = null


func _ready() -> void:
	_game_manager = get_node_or_null("/root/GameManager")
	if _game_manager == null:
		return
	var money_signal: Signal = _game_manager.get("money_changed")
	money_signal.connect(_on_money_changed)
	var day_signal: Signal = _game_manager.get("day_tick")
	day_signal.connect(_on_day_tick)
	var station_signal: Signal = _game_manager.get("station_changed")
	station_signal.connect(_on_station_changed)
	_on_money_changed(int(_game_manager.get("money")))
	_connect_inventarios()
	_refresh_info()


## Conecta los inventarios globales para refrescar el stock cuando cambia.
func _connect_inventarios() -> void:
	for clave in ["materia_prima", "warehouse"]:
		var inventario := _game_manager.get(clave) as Inventario
		if inventario != null:
			inventario.inventario_actualizado.connect(_on_inventory_changed)


func _on_money_changed(new_amount: int) -> void:
	money_label.text = "$%d" % new_amount


func _on_day_tick(seconds_remaining: float) -> void:
	var mins: int = int(seconds_remaining) / 60
	var secs: int = int(seconds_remaining) % 60
	timer_label.text = "%d:%02d" % [mins, secs]


func _on_inventory_changed(_item: ItemData, _cantidad: int) -> void:
	_refresh_info()


func _on_station_changed(_side: int) -> void:
	_refresh_info()


## Reconstruye el panel con la información de la sección visible. Se llama al
## entrar, al girar de estación y cada vez que cambia un inventario.
func _refresh_info() -> void:
	for child in info_list.get_children():
		info_list.remove_child(child)
		child.queue_free()
	if _game_manager == null:
		info_panel.visible = false
		return
	var balance: RunBalance = _game_manager.get("balance")
	if balance == null:
		info_panel.visible = false
		return
	match int(_game_manager.call("current_side")):
		SIDE_FRONT:
			_build_precios(balance)
		SIDE_LEFT:
			_build_materia_prima(balance)
		SIDE_RIGHT:
			_build_preparados(balance)
	info_panel.visible = info_list.get_child_count() > 0


## Estación principal: precio de cada plato/producto final.
func _build_precios(balance: RunBalance) -> void:
	if balance.platos_catalogo.is_empty():
		return
	_add_section("Precio por plato")
	for item in balance.platos_catalogo:
		if item == null:
			continue
		_add_row("%s   $%d" % [_nombre(item), item.price])


## Sección 2 (corte/desmenuce): unidades restantes de crudos y su cupo diario.
func _build_materia_prima(balance: RunBalance) -> void:
	var materia: Inventario = _game_manager.get("materia_prima")
	_add_section("Materia prima")
	for limite in balance.stock_limits:
		if limite == null or limite.item == null:
			continue
		var actual: int = materia.cantidad_de(limite.item) if materia != null else 0
		_add_row("%s   %d/%d" % [_nombre(limite.item), actual, limite.daily_limit])


## Sección 3 (preparación): unidades disponibles de ingredientes preparados.
func _build_preparados(balance: RunBalance) -> void:
	var almacen: Inventario = _game_manager.get("warehouse")
	_add_section("Ingredientes preparados")
	for item in balance.preparados_catalogo:
		if item == null:
			continue
		var actual: int = almacen.cantidad_de(item) if almacen != null else 0
		_add_row("%s   %d" % [_nombre(item), actual])


func _add_section(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.89, 0.78, 0.53))
	info_list.add_child(label)


func _add_row(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.9, 0.92, 0.9))
	info_list.add_child(label)


## Nombre visible del ítem (cae al item_id si no tiene nombre).
func _nombre(item: ItemData) -> String:
	return item.name if item.name != "" else item.item_id
