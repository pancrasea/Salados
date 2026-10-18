extends Resource
class_name RunBalance

## Datos de equilibrio de una partida. Centraliza los números que antes estaban
## dispersos entre `GameManager` (dinero, renta, duración) y las escenas
## (ritmo de clientes, paciencia). Los cupos de materia prima viven en
## `stock_limits`; los precios de venta, en `ItemData.price`.
##
## `GameManager` carga `resources/config/balance_default.tres` en `_ready()` y
## lo expone como `balance`. Si el recurso falta, GameManager usa sus constantes
## de respaldo para no romper arranques headless.

@export_group("Economía")
## Saldo inicial del jugador al empezar cada día.
@export var starting_money: int = 20
## Renta de la carreta que se cobra al terminar el día.
@export var rent_cost: int = 15

@export_group("Jornada")
## Duración del día en segundos.
@export_range(10.0, 600.0, 1.0) var day_duration: float = 120.0

@export_group("Recursos")
## Cupo diario de materia prima. Los ingredientes preparados quedan acotados
## de forma natural por estos cupos (no necesitan un límite propio).
@export var stock_limits: Array[StockItem] = []

@export_group("Clientes")
## Máximo de clientes simultáneos en la fila (tope duro del proyecto: 3).
@export_range(1, 3, 1) var max_customers: int = 3
## Segundos entre intentos automáticos de generar un cliente.
@export_range(0.1, 60.0, 0.1) var spawn_interval: float = 5.0
## Paciencia por defecto (segundos) para arquetipos que no definan la suya.
@export_range(1.0, 300.0, 1.0) var default_patience: float = 30.0

@export_group("Interfaz")
## Ingredientes preparados que el HUD muestra con su stock restante (los
## crudos salen de `stock_limits`). Solo afecta a la información en pantalla.
@export var preparados_catalogo: Array[ItemData] = []
## Platos/productos finales cuyo precio lista el HUD. Solo afecta a la UI.
@export var platos_catalogo: Array[ItemData] = []


## Límite diario configurado para un `ItemData` (0 si no está en la tabla).
func limite_de(item: ItemData) -> int:
	for limite in stock_limits:
		if limite != null and limite.item == item:
			return maxi(limite.daily_limit, 0)
	return 0
