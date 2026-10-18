extends Inventario
class_name AlmacenPreparados

## Almacén compartido entre la Sección 2 (corte/desmenuce) y la Sección 3
## (preparación). Acumula las unidades de cada ingrediente ya preparado y
## notifica a los suscriptores para que las fuentes de la Sección 3 se
## muestren o se oculten.
##
## Tiene un cupo de `MAX_POR_ITEM` por ingrediente (coincide con los
## `slots_per_item = 3` de la fuente `Ingredientes` de la Sección 3): no se
## puede acumular más de lo que esa fuente puede mostrar. Hereda la lógica de
## `Inventario`.

## Cupo máximo por ingrediente preparado (alineado con la fuente `Ingredientes`).
const MAX_POR_ITEM: int = 3


func _init() -> void:
	max_por_item = MAX_POR_ITEM


## Alias de compatibilidad: total de unidades preparadas acumuladas.
func total_preparados() -> int:
	return total()
