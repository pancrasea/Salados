extends Control

@onready var scene_layer: CanvasLayer = $SceneLayer
@onready var mouse_interaction: CanvasLayer = $MouseInteraction
@onready var hud: CanvasLayer = $HUD

# Escenas de pantallas
const MAIN_MENU_SCENE = preload("res://src/ui/MainMenu.tscn")
# Panel de resumen de fin de día (ganado/renta/saldo).
const END_OF_DAY_SCENE = preload("res://src/ui/EndOfDay.tscn")

# Escenas de las 4 estaciones
const MAIN_STATION_SCENE  = preload("res://src/entities/station/MainStation.tscn")
const LEFT_STATION_SCENE  = preload("res://src/entities/station/corte_desmenuce/CorteDesmenuce.tscn")
const RIGHT_STATION_SCENE = preload("res://src/entities/station/PreparationStation.tscn")
const BACK_STATION_SCENE  = preload("res://src/entities/station/BackStation.tscn")

func _ready() -> void:
	GameManager.main = self
	get_tree().paused = false
	mouse_interaction.hide()
	hud.hide()
	change_screen(MAIN_MENU_SCENE)


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
	# Registrar el CustomerSpawner de la estación principal en el HUD para que
	# muestre las órdenes activas en el panel inferior.
	var main_station: Node = stations.get(GameManager.Side.FRONT)
	if main_station != null:
		var spawner := main_station.get_node_or_null("CustomerSpawner") as CustomerSpawner
		if spawner != null:
			hud.call("register_spawner", spawner)
	# start_day diferido: el timer y el spawner arrancan al cerrar el banner.
	GameManager.start_day(true)
	GameManager.day_ended.connect(_on_day_ended, CONNECT_ONE_SHOT)
	get_tree().paused = false
	mouse_interaction.show()
	hud.show()
	# Banner de objetivo: onboarding mínimo. Al cerrarse arranca el día real.
	hud.call("show_objective_banner")
	var hud_typed := hud as Node
	hud_typed.connect("objective_banner_closed", _on_objective_banner_closed, CONNECT_ONE_SHOT)


# Llamado al volver al menú (oculta la UI de navegación)
func return_to_menu() -> void:
	GameManager.stop_day()
	get_tree().paused = false
	mouse_interaction.hide()
	hud.hide()
	change_screen(MAIN_MENU_SCENE)


# Llamado desde menu_pause cuando se pausa el juego
func on_game_paused() -> void:
	GameManager.stop_day()


# Llamado desde menu_pause cuando se reanuda el juego
func on_game_resumed() -> void:
	# Reanuda el timer con el tiempo que ya transcurrió (stop_day no resetea _day_elapsed)
	GameManager.resume_day()


# Lógica al terminar el día. Liquida la renta y muestra el resumen.
func _on_day_ended() -> void:
	GameManager.end_day()
	mouse_interaction.hide()
	hud.hide()
	get_tree().paused = true
	var panel := END_OF_DAY_SCENE.instantiate()
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(panel)


# Arranca el día y el spawner cuando el jugador cierra el banner de objetivo.
func _on_objective_banner_closed() -> void:
	# Arrancar el timer del día.
	GameManager.resume_day()
	# Arrancar el spawner de clientes.
	var main_station: Node = GameManager.call("get_station", GameManager.Side.FRONT)
	if main_station != null:
		var spawner := main_station.get_node_or_null("CustomerSpawner") as CustomerSpawner
		if spawner != null:
			spawner.start_spawning()
