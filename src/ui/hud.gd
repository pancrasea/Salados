extends CanvasLayer

## HUD de juego: muestra el dinero actual, el tiempo restante del día y un
## panel de información de la sección visible. El panel cambia según la
## estación: precios de platos en la principal, stock de materia prima en la
## Sección 2 (corte/desmenuce) y stock de preparados en la Sección 3
## (preparación). Se instancia en main.tscn como hijo permanente y se
## muestra/oculta junto con la sesión de juego.
##
## También muestra el panel de pedidos activos: hasta 3 tarjetas (OrderCard)
## que el spawner de clientes alimenta vía `register_spawner(spawner)`.

## Valores de GameManager.Side (FRONT, LEFT, RIGHT, BACK) repetidos como
## constantes locales para no depender del identificador global GameManager en
## arranques headless con `--script`.
const SIDE_FRONT: int = 0
const SIDE_LEFT: int = 1
const SIDE_RIGHT: int = 2

## Escena de tarjeta de pedido; se instancia en runtime según los clientes activos.
const ORDER_CARD_SCENE := preload("res://src/ui/order_card.tscn")

@onready var money_label: Label = %MoneyLabel
@onready var timer_label: Label = %TimerLabel
@onready var info_panel: PanelContainer = $InfoPanel
@onready var info_list: VBoxContainer = $InfoPanel/InfoList
@onready var hint_label: Label = $HintLabel
@onready var objective_banner: PanelContainer = $ObjectiveBanner

## Contenedor de tarjetas de pedido (añadido en hud.tscn).
@onready var orders_panel: HBoxContainer = $OrdersPanel

## Timer del auto-cierre del banner de objetivo; se reintenta si se vuelve a
## mostrar antes de que expire.
var _banner_timer: SceneTreeTimer = null

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
	_update_hint(int(_game_manager.call("current_side")))
	_update_orders_panel_visibility(int(_game_manager.call("current_side")))


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
	# Aviso de presión de tiempo: ámbar cerca del final y rojo (parpadeante) en
	# los últimos 10 s, para que el jugador sienta la urgencia.
	if seconds_remaining <= 10.0:
		timer_label.add_theme_color_override("font_color", Color(0.96, 0.35, 0.3))
		timer_label.modulate.a = 0.45 + 0.55 * absf(sin(Time.get_ticks_msec() / 180.0))
	elif seconds_remaining <= 30.0:
		timer_label.add_theme_color_override("font_color", Color(0.96, 0.76, 0.36))
		timer_label.modulate.a = 1.0
	else:
		timer_label.remove_theme_color_override("font_color")
		timer_label.modulate.a = 1.0


func _on_inventory_changed(_item: ItemData, _cantidad: int) -> void:
	_refresh_info()


func _on_station_changed(side: int) -> void:
	_refresh_info()
	_update_hint(side)
	# En la estación principal los pedidos se ven encima de cada cliente.
	# En las demás estaciones se muestran en el panel del HUD.
	_update_orders_panel_visibility(side)


## Muestra el OrdersPanel solo cuando no estamos en la estación principal.
func _update_orders_panel_visibility(side: int) -> void:
	if orders_panel == null:
		return
	var on_front := (side == SIDE_FRONT)
	# En FRONT: tarjetas del mundo visibles, panel del HUD oculto.
	# En otras: tarjetas del mundo ocultas (la estación no se ve), panel del HUD visible.
	orders_panel.visible = (not on_front) and orders_panel.get_child_count() > 0


## Instrucción breve y contextual según la sección visible. Da al jugador de
## jam una pista de qué hacer sin explicación externa.
func _update_hint(side: int) -> void:
	if hint_label == null:
		return
	match side:
		SIDE_FRONT:
			hint_label.text = "Arrastra los ingredientes a la bandeja y entrégala al cliente que la pida."
		SIDE_LEFT:
			hint_label.text = "Arrastra materia prima a la zona y haz 3 clics para prepararla."
		SIDE_RIGHT:
			hint_label.text = "Arma el plato (líquido + ingredientes) y despáchalo a la estación principal."
		_:
			hint_label.text = ""
	hint_label.visible = hint_label.text != ""


## Muestra el banner de objetivo al empezar la partida y lo cierra solo.
func show_objective_banner() -> void:
	if objective_banner == null:
		return
	objective_banner.modulate = Color(1.0, 1.0, 1.0, 0.0)
	objective_banner.show()
	var tween := create_tween()
	tween.tween_property(objective_banner, "modulate:a", 1.0, 0.35)
	if _banner_timer != null:
		_banner_timer.timeout.disconnect(_hide_objective_banner)
	_banner_timer = get_tree().create_timer(8.0)
	_banner_timer.timeout.connect(_hide_objective_banner)


func _hide_objective_banner() -> void:
	if objective_banner == null or not objective_banner.visible:
		return
	var tween := create_tween()
	tween.tween_property(objective_banner, "modulate:a", 0.0, 0.3)
	tween.tween_callback(objective_banner.hide)


func _on_objective_banner_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_hide_objective_banner()


## Reconstruye el panel con la información de la sección visible. Se llama al
## entrar, al girar de estación y cada vez que cambia un inventario.
func _refresh_info() -> void:
	info_list.visible = false
	#for child in info_list.get_children():
		#info_list.remove_child(child)
		#child.queue_free()
	#if _game_manager == null:
		#info_panel.visible = false
		#return
	#var balance: RunBalance = _game_manager.get("balance")
	#if balance == null:
		#info_panel.visible = false
		#return
	#match int(_game_manager.call("current_side")):
		#SIDE_FRONT:
			#_build_precios(balance)
		#SIDE_LEFT:
			#_build_materia_prima(balance)
		#SIDE_RIGHT:
			#_build_preparados(balance)
	#info_panel.visible = info_list.get_child_count() > 0


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


## Registra el CustomerSpawner cuyas órdenes se mostrarán en el panel.
## Conecta `customers_changed` para reconstruir las tarjetas cuando la fila cambia.
## Llamar desde main.gd tras instanciar la estación principal.
func register_spawner(spawner: CustomerSpawner) -> void:
	if spawner == null:
		return
	spawner.customers_changed.connect(_on_customers_changed)
	# Construir las tarjetas con los clientes que ya estén en la fila (si hay).
	_on_customers_changed(spawner.active_customers.duplicate())


## Reconstruye el panel de tarjetas cada vez que la fila de clientes cambia.
## `customers` es una copia del array de activos del spawner (puede estar vacío).
func _on_customers_changed(customers: Array) -> void:
	if orders_panel == null:
		return
	# Limpiar tarjetas anteriores desconectando sus señales primero.
	for child in orders_panel.get_children():
		orders_panel.remove_child(child)
		child.queue_free()
	# Crear una tarjeta por cliente activo, en orden de llegada (izquierda → derecha).
	for i in customers.size():
		var customer := customers[i] as CustomerBase
		if customer == null or not is_instance_valid(customer):
			continue
		var card := ORDER_CARD_SCENE.instantiate()
		orders_panel.add_child(card)
		# setup() necesita que el nodo esté en el árbol (para _ready del card).
		card.setup(customer, i)
	# Respetar visibilidad: solo mostrar si no estamos en la estación principal.
	var side := SIDE_FRONT
	if _game_manager != null:
		side = int(_game_manager.call("current_side"))
	_update_orders_panel_visibility(side)


func _on_pause_button_pressed() -> void:
	## Delega la pausa al MenuPause que vive en main.tscn bajo PauseLayer.
	## Se resuelve por ruta para no depender del identificador global GameManager
	## ni de una referencia directa entre nodos de distintas escenas.
	var menu_pause := get_node_or_null("/root/Main/PauseLayer/MenuPause")
	if menu_pause != null:
		menu_pause.call("_pause_game")
