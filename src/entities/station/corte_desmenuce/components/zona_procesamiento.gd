extends PanelContainer
class_name ZonaProcesamiento

## Zona de preparación. El modo central muestra hasta tres crudos en fila;
## `procesar_click` completa uno a la vez, de izquierda a derecha.
signal ingrediente_terminado(ingrediente_id: StringName)

## 2 acepta ambas preparaciones en la zona central; 0 y 1 conservan las zonas.
@export_enum("Cortar:0", "Desmenuzar:1", "Ambos:2") var tipo_aceptado: int = 0
@export var titulo_visible: String = "ZONA DE CORTE"
@export var ayuda_visible: String = "Haz tres clics para preparar el ingrediente"

const MAX_INGREDIENTES: int = 3

var actual: EncebolladoIngrediente
var clics: int = 0
var _ingredientes: Array[EncebolladoIngrediente] = [null, null, null]
var _clics_completados: int = 0

@onready var titulo: Label = $Contenido/Titulo
@onready var instruccion: Label = $Contenido/Instruccion
@onready var etiqueta_ingrediente: Label = $Contenido/Ingrediente
@onready var icono_ingrediente: TextureRect = $Contenido/IconoIngrediente
@onready var fila: HBoxContainer = $Contenido/FilaIngredientes
@onready var indicador: Label = $Contenido/IndicadorClics
@onready var barra: ProgressBar = $Contenido/BarraProgreso
@onready var estado: Label = $Contenido/Estado

func _ready() -> void:
	titulo.text = titulo_visible
	instruccion.text = ayuda_visible
	fila.visible = tipo_aceptado == 2
	if tipo_aceptado == 2:
		# El DropArea recibe los clics; la UI solo muestra los iconos.
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
		($Contenido as VBoxContainer).alignment = BoxContainer.ALIGNMENT_CENTER
		etiqueta_ingrediente.hide()
		estado.hide()
		indicador.hide()
		barra.hide()
		for indice in range(MAX_INGREDIENTES):
			_dibujar_espacio(indice)
	_dibujar_estado()

## Conserva el significado original: hay al menos un ingrediente en proceso.
func esta_ocupada() -> bool:
	if tipo_aceptado == 2:
		return cantidad_en_fila() > 0
	return actual != null

## Permite otro crudo solo cuando queda un espacio libre en la fila central.
func tiene_espacio() -> bool:
	if tipo_aceptado == 2:
		return cantidad_en_fila() < MAX_INGREDIENTES
	return not esta_ocupada()

func cantidad_en_fila() -> int:
	var cantidad := 0
	for dato in _ingredientes:
		if dato != null:
			cantidad += 1
	return cantidad

## Cuenta los crudos pendientes cuyo preparado ocupará cupo en el almacén.
func pendientes_de(item: ItemData) -> int:
	var cantidad := 0
	for dato in _ingredientes:
		if dato != null and dato.item_entrada == item:
			cantidad += 1
	return cantidad

func primer_pendiente() -> EncebolladoIngrediente:
	for dato in _ingredientes:
		if dato != null:
			return dato
	return null

## Puntos de todo el lote: cada crudo añade sus clics y los completados quedan
## marcados hasta vaciar la fila. Se muestran arriba del DropArea.
func puntos_progreso() -> String:
	if cantidad_en_fila() == 0:
		return ""
	var total := _clics_completados
	for dato in _ingredientes:
		if dato != null:
			total += dato.clics_necesarios
	var hechos := _clics_completados + clics
	var puntos: PackedStringArray = []
	for indice in range(total):
		puntos.append("●" if indice < hechos else "○")
	return " ".join(puntos)

## Añade al primer espacio libre sin reiniciar los clics de los demás.
func empezar(dato: EncebolladoIngrediente) -> void:
	if dato == null:
		return
	if tipo_aceptado != 2 and int(dato.preparacion) != tipo_aceptado:
		return
	if tipo_aceptado == 2:
		for indice in range(MAX_INGREDIENTES):
			if _ingredientes[indice] == null:
				_ingredientes[indice] = dato
				_dibujar_espacio(indice)
				return
		return
	if actual != null:
		return
	actual = dato
	clics = 0
	_dibujar_estado()

func _gui_input(event: InputEvent) -> void:
	if tipo_aceptado == 2 or actual == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		clics = min(clics + 1, actual.clics_necesarios)
		
		match actual.id:
			&"cebolla_colorada":
				AudioManager.play_sound(
					AudioManager.SFX.Cortando_Cebolla
				)
			&"yuca":
				AudioManager.play_sound(
					AudioManager.SFX.Cortar_Yuca
				)
			&"albacora":
				AudioManager.play_sound(
					AudioManager.SFX.Deshilachar
				)

		var terminado: bool = clics >= actual.clics_necesarios
		var terminado_id: StringName = actual.id
		var texto_final: String = actual.texto_resultado()
		_dibujar_estado()
		accept_event()
		if terminado:
			actual = null
			icono_ingrediente.texture = null
			icono_ingrediente.hide()
			etiqueta_ingrediente.text = "✓ " + texto_final
			estado.text = "¡Ingrediente preparado!"
			indicador.text = "✓ Preparación completa"
			ingrediente_terminado.emit(terminado_id)

## Un clic en cualquier punto del DropArea avanza solo el primer ingrediente.
func procesar_click() -> void:
	if tipo_aceptado != 2 or _ingredientes[0] == null:
		return
	var dato := _ingredientes[0]
	clics = mini(clics + 1, dato.clics_necesarios)
	if clics >= dato.clics_necesarios:
		_clics_completados += dato.clics_necesarios
		_ingredientes.remove_at(0)
		_ingredientes.append(null)
		clics = 0
		if cantidad_en_fila() == 0:
			_clics_completados = 0
		for indice in range(MAX_INGREDIENTES):
			_dibujar_espacio(indice)
		ingrediente_terminado.emit(dato.id)

func _dibujar_espacio(indice: int) -> void:
	var espacio := fila.get_child(indice) as Control
	var icono := espacio.get_node("Icono") as TextureRect
	var dato := _ingredientes[indice]
	icono.texture = dato.item_entrada.icon if dato != null and dato.item_entrada != null else null
	icono.visible = icono.texture != null

func _dibujar_estado() -> void:
	if tipo_aceptado == 2:
		add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		return

	var estilo := StyleBoxFlat.new()
	var tipo_visible := int(actual.preparacion) if actual != null else tipo_aceptado
	estilo.bg_color = Color("eff5fc00")
	estilo.border_color = Color("eff5fc00")
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(12)
	estilo.content_margin_left = 14
	estilo.content_margin_top = 12
	estilo.content_margin_right = 14
	estilo.content_margin_bottom = 12
	add_theme_stylebox_override("panel", estilo)

	if actual == null:
		icono_ingrediente.texture = null
		icono_ingrediente.hide()
		etiqueta_ingrediente.text = "Zona disponible"
		indicador.text = "○ ○ ○"
		barra.max_value = 3
		barra.value = 0
		estado.text = "Arrastra aquí un ingrediente"
		return

	etiqueta_ingrediente.text = actual.nombre_visible
	icono_ingrediente.texture = actual.item_entrada.icon if actual.item_entrada != null else null
	icono_ingrediente.visible = icono_ingrediente.texture != null
	barra.max_value = actual.clics_necesarios
	barra.value = clics
	var marcas: PackedStringArray = []
	for i in range(actual.clics_necesarios):
		marcas.append("●" if i < clics else "○")
	indicador.text = " ".join(marcas)
	estado.text = "%d / %d clics" % [clics, actual.clics_necesarios]
