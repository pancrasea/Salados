class_name ExprimidorItem extends BaseItem

@onready var jar_full: Sprite2D = $JarFull
@onready var jar_step1: Sprite2D = $JarStep1
@onready var jar_empty: Sprite2D = $JarEmpty

var disabled: bool = false
const CARGAS_JARRA: int = 3

func actualizar_nivel(cargas_restantes: int) -> void:
	disabled = cargas_restantes <= 0
	jar_full.visible = cargas_restantes >= CARGAS_JARRA
	jar_step1.visible = cargas_restantes > 0 and cargas_restantes < CARGAS_JARRA
	jar_empty.visible = disabled
