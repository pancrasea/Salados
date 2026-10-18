extends Resource
class_name StockItem

## Cupo diario de un recurso limitado (materia prima de la Sección 2).
## Se configura como sub-recurso dentro de `RunBalance.stock_limits`.
## `GameManager` lo traduce a `Inventario.configurar_limite()` al arrancar.
@export var item: ItemData
## Unidades disponibles al iniciar cada día. 0 = sin límite (no se configura cupo).
@export_range(0, 999, 1) var daily_limit: int = 8
