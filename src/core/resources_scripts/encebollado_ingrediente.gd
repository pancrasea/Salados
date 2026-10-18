extends Resource
class_name EncebolladoIngrediente

## Solo reglas de corte y desmenuce. La clase ItemData del equipo no cambia.
enum Preparacion { CORTAR, DESMENUZAR }

@export var id: StringName
@export var nombre_visible: String
@export var preparacion: Preparacion = Preparacion.CORTAR
@export_range(1, 20, 1) var clics_necesarios: int = 3
@export var resultado_visible: String = ""
@export var item_entrada: ItemData

func se_puede_preparar() -> bool:
	return item_entrada != null and item_entrada.next_data_state != null

func texto_resultado() -> String:
	if resultado_visible.strip_edges() != "":
		return resultado_visible
	return nombre_visible + " preparado"
