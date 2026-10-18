extends Control
class_name Seccion3Preparacion

## SECCIÓN 3. Solo muestra el inventario de preparados.
## Su escena no corta, no desmenuza y no crea materias primas.
signal volver_a_corte

var almacen: AlmacenPreparados = null
@onready var pilas: GridContainer = $Pilas
@onready var total_general: Label = $TotalGeneral
@onready var boton_volver: Button = $BotonVolver

func _ready() -> void:
    boton_volver.pressed.connect(func() -> void: volver_a_corte.emit())
    _actualizar_todas()

func configurar_almacen(nuevo_almacen: AlmacenPreparados) -> void:
    almacen = nuevo_almacen
    if not almacen.inventario_actualizado.is_connected(_cuando_cambia):
        almacen.inventario_actualizado.connect(_cuando_cambia)
    _actualizar_todas()

func _cuando_cambia(_item: ItemData, _cantidad: int) -> void:
    _actualizar_todas()

func _actualizar_todas() -> void:
    if not is_node_ready():
        return
    for control in pilas.get_children():
        var pila: PilaIngrediente = control as PilaIngrediente
        if pila != null:
            pila.actualizar(almacen.cantidad_de(pila.item_preparado) if almacen != null else 0)
    total_general.text = "Total de ingredientes preparados: %d" % (almacen.total_preparados() if almacen != null else 0)
