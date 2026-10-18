extends Node2D

## DEMOSTRACIÓN INDEPENDIENTE. No cambia GameManager ni los scripts del main.
## Sección 2: arrastrar BaseItem, cinco clics y reponer materia prima.
## Sección 3: leer del almacén las cantidades preparadas.
const ESCENA_ITEM: PackedScene = preload("res://src/entities/item/base_item.tscn")
const ENTRADAS: Array[Resource] = [
    preload("res://resources/items/item_cebolla_colorada.tres"),
    preload("res://resources/items/item_cilantro.tres"),
    preload("res://resources/items/item_yuca.tres"),
    preload("res://resources/items/item_albacora.tres")
]
const POSICIONES: Array[Vector2] = [
    Vector2(115, 238), Vector2(296, 238),
    Vector2(115, 411), Vector2(296, 411)
]

var entradas_por_resultado: Dictionary = {}
var posiciones_por_resultado: Dictionary = {}
@onready var seccion_2: Node2D = $Seccion2
@onready var estacion: CorteDesmenuce = $Seccion2/CorteDesmenuce
@onready var seccion_3: Seccion3Preparacion = $Seccion3
@onready var almacen: AlmacenPreparados = $AlmacenPreparados
@onready var ayuda_resultado: Label = $Seccion2/Rotulos/AyudaResultado
@onready var resumen: Label = $Seccion2/Rotulos/ResumenPreparados
@onready var boton_ir: Button = $Seccion2/Rotulos/BotonIrSeccion3
@onready var borde_derecho: Button = $NavegacionBordes/BordeDerecho
@onready var borde_izquierdo: Button = $NavegacionBordes/BordeIzquierdo

func _ready() -> void:
    estacion.item_preparado.connect(_cuando_sale_item)
    almacen.inventario_actualizado.connect(_cuando_cambia_almacen)
    boton_ir.pressed.connect(_abrir_seccion_3)
    borde_derecho.pressed.connect(_abrir_seccion_3)
    borde_izquierdo.pressed.connect(_abrir_seccion_2)
    seccion_3.volver_a_corte.connect(_abrir_seccion_2)
    seccion_3.configurar_almacen(almacen)

    for i in range(ENTRADAS.size()):
        var entrada: ItemData = ENTRADAS[i] as ItemData
        if entrada == null or entrada.next_data_state == null:
            continue
        var resultado_clave: String = entrada.next_data_state.resource_path
        entradas_por_resultado[resultado_clave] = entrada
        posiciones_por_resultado[resultado_clave] = POSICIONES[i]
        _crear_objeto(entrada, POSICIONES[i])
    _actualizar_resumen()
    _abrir_seccion_2()

func _crear_objeto(datos: ItemData, posicion: Vector2) -> void:
    var objeto: BaseItem = ESCENA_ITEM.instantiate() as BaseItem
    if objeto == null:
        return
    objeto.data = datos
    seccion_2.add_child(objeto)
    objeto.global_position = posicion
    # Mismo ícono predeterminado del Godot original.
    objeto.sprite_2d.scale = Vector2(0.30, 0.30)

func _cuando_sale_item(resultado: ItemData) -> void:
    if resultado == null:
        return
    # Primero almacenamos el resultado, que la sección 3 muestra automáticamente.
    almacen.agregar(resultado)

    # Reponemos el producto crudo para que la prueba no tenga límite de unidades.
    var clave: String = resultado.resource_path
    if entradas_por_resultado.has(clave):
        var entrada: ItemData = entradas_por_resultado[clave] as ItemData
        var posicion: Vector2 = posiciones_por_resultado[clave]
        _crear_objeto(entrada, posicion)
    ayuda_resultado.text = "%s enviado a preparación (total: %d)." % [
        resultado.name, almacen.cantidad_de(resultado)
    ]

func _cuando_cambia_almacen(_item: ItemData, _cantidad: int) -> void:
    _actualizar_resumen()

func _actualizar_resumen() -> void:
    var cebolla: ItemData = ENTRADAS[0] as ItemData
    var cilantro: ItemData = ENTRADAS[1] as ItemData
    var yuca: ItemData = ENTRADAS[2] as ItemData
    var albacora: ItemData = ENTRADAS[3] as ItemData
    resumen.text = "Listos: Cebolla %d · Cilantro %d\nYuca %d · Albacora %d" % [
        almacen.cantidad_de(cebolla.next_data_state),
        almacen.cantidad_de(cilantro.next_data_state),
        almacen.cantidad_de(yuca.next_data_state),
        almacen.cantidad_de(albacora.next_data_state)
    ]

## Navegación con clics en los bordes (similar a los laterales del main).
## Las dos secciones se mantienen instanciadas: no hay cambio de escena ni se
## reinicia AlmacenPreparados. Evitamos navegar mientras se arrastra BaseItem.
func _abrir_seccion_3() -> void:
    if BaseItem.current_item_dragging != null:
        return
    seccion_2.visible = false
    seccion_3.visible = true
    _actualizar_bordes()

func _abrir_seccion_2() -> void:
    if BaseItem.current_item_dragging != null:
        return
    seccion_3.visible = false
    seccion_2.visible = true
    _actualizar_bordes()

func _actualizar_bordes() -> void:
    borde_derecho.visible = seccion_2.visible
    borde_izquierdo.visible = seccion_3.visible
