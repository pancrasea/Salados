extends Inventario
class_name AlmacenPreparados

## Almacén compartido entre la Sección 2 (corte/desmenuce) y la Sección 3
## (preparación). Acumula las unidades de cada ingrediente ya preparado y
## notifica a los suscriptores para que las fuentes de la Sección 3 se
## muestren o se oculten.
##
## No tiene cupo propio: su cantidad queda acotada por el cupo diario de
## materia prima de `GameManager.materia_prima` (cada crudo procesado produce
## como mucho un preparado). Hereda la lógica de `Inventario`.


## Alias de compatibilidad: total de unidades preparadas acumuladas.
func total_preparados() -> int:
	return total()
