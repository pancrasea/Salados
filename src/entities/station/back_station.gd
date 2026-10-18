extends Station

@onready var jugo_spawn: Node2D = $JugoSpawn
@onready var jugo_progress: ProgressBar = $JugoProgress
@onready var default_max_progress = 50
@onready var jugo_data : ItemData = preload("res://resources/items/jugo_naranja.tres")

var fruits_progress: Dictionary[BaseItem, int]

func _ready() -> void:
	GameEvents.exprimiendo_jugo.connect(_on_jugo_exprimiendo)
	jugo_progress.value = 100.0

func _on_jugo_exprimiendo(item: BaseItem) -> void:
	if item not in fruits_progress.keys():
		fruits_progress[item] = default_max_progress
	
	fruits_progress[item]-= 1
	jugo_progress.value-= 1.0
	
	if fruits_progress[item] == 0:
		fruits_progress.erase(item)
		item.queue_free()
		print("EXPRIMIDA POR COMPLETO")
	
	if jugo_progress.value == 0.0:
		jugo_progress.value = 100.0
		var jugo  = preload("res://src/entities/item/base_item.tscn").instantiate() as BaseItem
		jugo._transform_into(jugo_data)
		jugo.global_position = jugo_spawn.global_position
		add_child(jugo)
		print("JUGO LISTO")
