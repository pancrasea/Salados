extends Node
class_name Inventario

## Inventario genérico de unidades de `ItemData`, con clave por `item_id`
## (fallback `resource_path`). Maneja una cantidad disponible por ítem y,
## opcionalmente, un **cupo diario** que se repone con `reset_dia()`.
##
## Usos actuales:
## - `GameManager.materia_prima`: materia prima de la Sección 2, con cupo diario
##   (configurado desde `RunBalance.stock_limits`).
## - `AlmacenPreparados`: ingredientes preparados de la Sección 3, sin cupo
##   (solo acumula lo que produce el corte/desmenuce).
##
## La señal `inventario_actualizado` avisa a las fuentes (`FoodSpawner`) para
## que muestren u oculten un ingrediente según haya stock.
signal inventario_actualizado(item: ItemData, cantidad: int)

## clave -> int (cupo diario). Solo se guardan los ítems con límite.
var _limites: Dictionary = {}
## clave -> ItemData, para poder emitir la señal sin depender del llamador.
var _items: Dictionary = {}
## clave -> int (unidades disponibles ahora).
var _cantidades: Dictionary = {}


## Define el cupo diario de un ítem. `limite <= 0` quita el límite.
func configurar_limite(item: ItemData, limite: int) -> void:
	var clave := _clave_de(item)
	if clave == "":
		return
	_items[clave] = item
	if limite > 0:
		_limites[clave] = limite
	else:
		_limites.erase(clave)


## Registra unidades disponibles. Devuelve la cantidad resultante.
func agregar(item: ItemData, cantidad: int = 1) -> int:
	var clave := _clave_de(item)
	if clave == "" or cantidad <= 0:
		push_warning("Inventario: ItemData sin item_id ni resource_path, o cantidad no positiva.")
		return 0
	_items[clave] = item
	var total: int = int(_cantidades.get(clave, 0)) + cantidad
	_cantidades[clave] = total
	inventario_actualizado.emit(item, total)
	return total


## Consume `cantidad` unidades. Devuelve true solo si había stock suficiente
## (en cuyo caso descuenta; si no, deja el inventario intacto).
func consumir(item: ItemData, cantidad: int = 1) -> bool:
	var clave := _clave_de(item)
	if clave == "" or cantidad <= 0:
		return false
	var disponible: int = int(_cantidades.get(clave, 0))
	if disponible < cantidad:
		return false
	disponible -= cantidad
	_items[clave] = item
	if disponible > 0:
		_cantidades[clave] = disponible
	else:
		_cantidades.erase(clave)
	inventario_actualizado.emit(item, disponible)
	return true


func cantidad_de(item: ItemData) -> int:
	var clave := _clave_de(item)
	if clave == "":
		return 0
	return int(_cantidades.get(clave, 0))


func tiene_stock(item: ItemData) -> bool:
	return cantidad_de(item) > 0


func total() -> int:
	var suma: int = 0
	for valor in _cantidades.values():
		suma += int(valor)
	return suma


## Rellena cada ítem configurado hasta su cupo diario y emite un aviso por ítem.
func reset_dia() -> void:
	_cantidades.clear()
	for clave in _limites:
		_cantidades[clave] = int(_limites[clave])
		inventario_actualizado.emit(_items.get(clave), int(_limites[clave]))


## Vacía todo el inventario (p. ej. los preparados al empezar un día).
func reset() -> void:
	_cantidades.clear()
	inventario_actualizado.emit(null, 0)


func _clave_de(item: ItemData) -> String:
	if item == null:
		return ""
	if item.item_id != "":
		return item.item_id
	return item.resource_path
