extends Station
class_name CorteDesmenuce

## SECCIÓN 2. Mantiene la interfaz original y las clases ItemData/BaseItem.
## Recibe UN ingrediente por vez y permite preparar cantidades ilimitadas.
## La señal item_preparado entrega el ItemData de salida a la escena principal.
signal item_preparado(item: ItemData)

const RECETAS: Array[Resource] = [
    preload("res://resources/items/encebollado_cebolla_colorada.tres"),
    preload("res://resources/items/encebollado_cilantro.tres"),
    preload("res://resources/items/encebollado_albacora.tres"),
    preload("res://resources/items/encebollado_yuca.tres")
]

var entrada_activa: ItemData = null
var ingrediente_activo: StringName = &""
var total_procesados: int = 0

@onready var zona_corte: ZonaProcesamiento = %ZonaCorte
@onready var zona_desmenuce: ZonaProcesamiento = %ZonaDesmenuce
@onready var mensaje: Label = %Mensaje
@onready var progreso: Label = %ProgresoTotal

func _ready() -> void:
    zona_corte.ingrediente_terminado.connect(_cuando_termina_ingrediente)
    zona_desmenuce.ingrediente_terminado.connect(_cuando_termina_ingrediente)
    _refrescar_progreso()

## BaseItem llama recibir_item al soltarse sobre el Area2D DropArea.
func recibir_item(item: ItemData) -> bool:
    if item == null or item.next_data_state == null:
        return false

    var dato: EncebolladoIngrediente = _buscar_por_item(item)
    if dato == null or not dato.se_puede_preparar():
        return false

    # No duplicar la preparación mientras ya hay un ingrediente en curso.
    if ingrediente_activo != &"":
        return false

    var zona: ZonaProcesamiento = _zona_para(dato)
    if zona == null or zona.esta_ocupada():
        return false

    entrada_activa = item
    ingrediente_activo = dato.id
    zona.empezar(dato)
    mensaje.text = "%s: haz %d clics para %s." % [
        dato.nombre_visible,
        dato.clics_necesarios,
        "cortar" if dato.preparacion == EncebolladoIngrediente.Preparacion.CORTAR else "desmenuzar"
    ]
    return true

func _zona_para(dato: EncebolladoIngrediente) -> ZonaProcesamiento:
    if dato.preparacion == EncebolladoIngrediente.Preparacion.CORTAR:
        return zona_corte
    if dato.preparacion == EncebolladoIngrediente.Preparacion.DESMENUZAR:
        return zona_desmenuce
    return null

func _buscar_por_item(item: ItemData) -> EncebolladoIngrediente:
    for recurso in RECETAS:
        var dato: EncebolladoIngrediente = recurso as EncebolladoIngrediente
        if dato != null and dato.item_entrada == item:
            return dato
    return null

func _cuando_termina_ingrediente(id: StringName) -> void:
    if entrada_activa == null or ingrediente_activo != id:
        return
    var salida: ItemData = entrada_activa.next_data_state
    # Limpiamos para admitir otra cebolla, yuca, etc. sin límite.
    entrada_activa = null
    ingrediente_activo = &""
    if salida == null:
        mensaje.text = "No se encontró el estado preparado del ingrediente."
        return
    total_procesados += 1
    _refrescar_progreso()
    mensaje.text = "%s listo: enviado a la sección 3." % salida.name
    item_preparado.emit(salida)

func _refrescar_progreso() -> void:
    progreso.text = "Total preparado: %d" % total_procesados
