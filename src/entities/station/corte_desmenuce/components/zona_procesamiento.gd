extends PanelContainer
class_name ZonaProcesamiento

## Zona interactiva de corte o desmenuce de la Sección 2. Gestiona un único
## ingrediente recibido desde CorteDesmenuce: el jugador hace clics encima
## (por defecto 3, según `EncebolladoIngrediente.clics_necesarios`) y al
## completarlos emite `ingrediente_terminado`. No maneja sprites ni un segundo
## sistema de arrastrar y soltar.
signal ingrediente_terminado(ingrediente_id: StringName)

@export_enum("Cortar:0", "Desmenuzar:1") var tipo_aceptado: int = 0
@export var titulo_visible: String = "ZONA DE CORTE"
@export var ayuda_visible: String = "Haz tres clics para preparar el ingrediente"

var actual: EncebolladoIngrediente
var clics: int = 0

@onready var titulo: Label = $Contenido/Titulo
@onready var instruccion: Label = $Contenido/Instruccion
@onready var etiqueta_ingrediente: Label = $Contenido/Ingrediente
@onready var indicador: Label = $Contenido/IndicadorClics
@onready var barra: ProgressBar = $Contenido/BarraProgreso
@onready var estado: Label = $Contenido/Estado

func _ready() -> void:
	titulo.text = titulo_visible
	instruccion.text = ayuda_visible
	_dibujar_estado()

func esta_ocupada() -> bool:
	return actual != null

func empezar(dato: EncebolladoIngrediente) -> void:
	if actual != null or dato == null or int(dato.preparacion) != tipo_aceptado:
		return
	actual = dato
	clics = 0
	_dibujar_estado()

func _gui_input(event: InputEvent) -> void:
	if actual == null:
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
			etiqueta_ingrediente.text = "✓ " + texto_final
			estado.text = "¡Ingrediente preparado!"
			indicador.text = "✓ Preparación completa"
			ingrediente_terminado.emit(terminado_id)

func _dibujar_estado() -> void:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color("#fff5df") if tipo_aceptado == 0 else Color("#eff5fc")
	estilo.border_color = Color("#a78651") if tipo_aceptado == 0 else Color("#6c8ab0")
	estilo.set_border_width_all(3)
	estilo.set_corner_radius_all(12)
	estilo.content_margin_left = 14
	estilo.content_margin_top = 12
	estilo.content_margin_right = 14
	estilo.content_margin_bottom = 12
	add_theme_stylebox_override("panel", estilo)

	if actual == null:
		etiqueta_ingrediente.text = "Zona disponible"
		indicador.text = "○ ○ ○"
		barra.max_value = 3
		barra.value = 0
		estado.text = "Arrastra aquí un ingrediente"
		return

	etiqueta_ingrediente.text = actual.nombre_visible
	barra.max_value = actual.clics_necesarios
	barra.value = clics
	var marcas: PackedStringArray = []
	for i in range(actual.clics_necesarios):
		marcas.append("●" if i < clics else "○")
	indicador.text = " ".join(marcas)
	estado.text = "%d / %d clics" % [clics, actual.clics_necesarios]
