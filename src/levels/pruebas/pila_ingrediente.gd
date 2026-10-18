extends PanelContainer
class_name PilaIngrediente

## Vista de una pila de tres slots. Cada slot admite varias unidades.
## La cantidad real reside en AlmacenPreparados, NO en este Control.
@export var item_preparado: ItemData

@onready var nombre: Label = $Contenido/Nombre
@onready var total: Label = $Contenido/Total
@onready var casillas: Array = [
    $Contenido/Slots/Slot1/Cantidad,
    $Contenido/Slots/Slot2/Cantidad,
    $Contenido/Slots/Slot3/Cantidad
]

func _ready() -> void:
    if item_preparado != null:
        nombre.text = item_preparado.name
    actualizar(0)

func actualizar(cantidad: int) -> void:
    total.text = "Total listo: %d" % cantidad
    # Reparto visual equilibrado: 5 unidades = 2 / 2 / 1.
    # No existe un máximo de 3; cada casilla representa una pila.
    var base: int = int(cantidad / 3)
    var sobrantes: int = cantidad % 3
    for i in range(3):
        var unidades: int = base + (1 if i < sobrantes else 0)
        var etiqueta: Label = casillas[i] as Label
        etiqueta.text = "×%d" % unidades if unidades > 0 else "Vacío"
