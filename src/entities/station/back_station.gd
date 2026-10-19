class_name BackStation extends Station

@onready var jugo_spawn: Node2D = $JugoSpawn
@onready var jugo_progress: ProgressBar = $JugoProgress
@onready var exprimidor: ExprimidorItem = $ExprimidorItem
const PASOS_POR_JUGO: int = 100
const MAX_JUGOS: int = 3
@onready var jugo_data : ItemData = preload("res://resources/items/jugo_naranja.tres")

var fruits_progress: Dictionary[BaseItem, int]
## Jugos producidos desde la última recarga de esta jarra.
var jugos_producidos: int = 0

func _ready() -> void:
	GameEvents.exprimiendo_jugo.connect(_on_jugo_exprimiendo)
	jugo_progress.value = 100.0
	exprimidor.actualizar_nivel(MAX_JUGOS - jugos_producidos)

## Repone las tres cargas y habilita de nuevo el exprimidor. También descarta
## cualquier progreso parcial de una fruta anterior a la recarga.
func refill_jugos() -> void:
	jugos_producidos = 0
	fruits_progress.clear()
	jugo_progress.value = 100.0
	exprimidor.actualizar_nivel(MAX_JUGOS)

func _on_jugo_exprimiendo(item: BaseItem) -> void:
	if exprimidor.disabled or not is_instance_valid(item) or item.is_queued_for_deletion():
		return
	if item not in fruits_progress.keys():
		fruits_progress[item] = PASOS_POR_JUGO
	
	fruits_progress[item]-= 1
	jugo_progress.value-= 1.0
	
	if fruits_progress[item] == 0:
		AudioManager.play_sound(AudioManager.SFX.Exprimir_Limon)
		fruits_progress.erase(item)
		item.queue_free()
		print("EXPRIMIDA POR COMPLETO")
	
	if jugo_progress.value == 0.0:
		var jugo  = preload("res://src/entities/item/base_item.tscn").instantiate() as BaseItem
		jugo._transform_into(jugo_data)
		jugo.global_position = jugo_spawn.global_position
		add_child(jugo)
		jugos_producidos += 1
		# La jarra actualiza el sprite y se deshabilita al llegar a cero.
		exprimidor.actualizar_nivel(MAX_JUGOS - jugos_producidos)
		if jugos_producidos < MAX_JUGOS:
			jugo_progress.value = 100.0
		print("JUGO LISTO")
		var sprite_index: int = MAX_JUGOS - jugos_producidos
		print("Jugos restantes en la jarra: %d" % (sprite_index))
