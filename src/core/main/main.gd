extends Control

@onready var scene_layer: CanvasLayer = $SceneLayer
@onready var mouse_interaction: CanvasLayer = $MouseInteraction
@onready var hud: CanvasLayer = $HUD
@onready var datos_partida: DatosPartida = $DatosPartida
@onready var panel_datos_partida: PanelDatosPartida = $PanelDatosPartida

# Escenas de pantallas
const MAIN_MENU_SCENE = preload("res://src/ui/MainMenu.tscn")

# Escenas de las 4 estaciones
const MAIN_STATION_SCENE  = preload("res://src/entities/station/MainStation.tscn")
const LEFT_STATION_SCENE  = preload("res://src/entities/station/corte_desmenuce/CorteDesmenuce.tscn")
const RIGHT_STATION_SCENE = preload("res://src/entities/station/PreparationStation.tscn")
const BACK_STATION_SCENE  = preload("res://src/entities/station/BackStation.tscn")

func _ready() -> void:
	GameManager.main = self
	mouse_interaction.hide()
	hud.hide()
	change_screen(MAIN_MENU_SCENE)
	# El menu principal debe permanecer limpio: el HUD solo aparece en partida.
	panel_datos_partida.vincular(datos_partida)
	panel_datos_partida.hide()


# Limpia SceneLayer y carga la nueva pantalla
func change_screen(scene: PackedScene) -> void:
	for child in scene_layer.get_children():
		child.queue_free()
	scene_layer.add_child(scene.instantiate())


# Inicia el juego: instancia las 4 estaciones en SceneLayer y las registra en GameManager
func start_game() -> void:
	# Limpiar pantalla anterior
	for child in scene_layer.get_children():
		child.queue_free()

	var stations: Dictionary = {}

	var configs: Array = [
		[GameManager.Side.FRONT, MAIN_STATION_SCENE],
		[GameManager.Side.LEFT,  LEFT_STATION_SCENE],
		[GameManager.Side.RIGHT, RIGHT_STATION_SCENE],
		[GameManager.Side.BACK,  BACK_STATION_SCENE],
	]

	for cfg in configs:
		var side: int = cfg[0]
		var packed: PackedScene = cfg[1]
		var node := packed.instantiate()
		node.hide()
		scene_layer.add_child(node)
		stations[side] = node

	GameManager.setup_stations(stations)
	# La Sección 2 (corte/desmenuce) alimenta el almacén que consume la
	# Sección 3 (preparación).
	var corte := stations.get(GameManager.Side.LEFT) as CorteDesmenuce
	if corte != null and GameManager.warehouse != null:
		corte.item_preparado.connect(GameManager.warehouse.agregar)
	GameManager.start_day()
	# Crear estadísticas al iniciar la jornada, sin cambiar el dinero ni las estaciones.
	datos_partida.iniciar_partida(false)
	var frontal: Station = stations.get(GameManager.Side.FRONT)
	if frontal != null:
		var spawner: CustomerSpawner = frontal.get_node_or_null("CustomerSpawner") as CustomerSpawner
		datos_partida.conectar_generador_clientes(spawner)
	# Escuchar la misma fuente de inventario que ya usan Corte y Preparación.
	var almacen: AlmacenPreparados = GameManager.warehouse
	if almacen != null and not almacen.inventario_actualizado.is_connected(_actualizar_inventario_preparado):
		almacen.inventario_actualizado.connect(_actualizar_inventario_preparado)
	# Evitar conexiones duplicadas al iniciar otra partida tras volver al menu.
	if not GameManager.day_ended.is_connected(_on_day_ended):
		GameManager.day_ended.connect(_on_day_ended, CONNECT_ONE_SHOT)
	mouse_interaction.show()
	hud.show()
	# Los datos solo aparecen una vez iniciada la partida.
	panel_datos_partida.show()


func _actualizar_inventario_preparado(item: ItemData, cantidad: int) -> void:
	if item != null:
		datos_partida.inventario.establecer(InventarioPartida.Categoria.INGREDIENTES, item, cantidad)


# Llamado al volver al menú (oculta la UI de navegación)
func return_to_menu() -> void:
	GameManager.stop_day()
	mouse_interaction.hide()
	hud.hide()
	panel_datos_partida.hide()
	if GameManager.day_ended.is_connected(_on_day_ended):
		GameManager.day_ended.disconnect(_on_day_ended)
	change_screen(MAIN_MENU_SCENE)


# Lógica al terminar el día
func _on_day_ended() -> void:
	mouse_interaction.hide()
	hud.hide()
	panel_datos_partida.hide()
	# TODO: change_screen(END_OF_DAY_SCENE) cuando exista esa pantalla
	change_screen(MAIN_MENU_SCENE)
