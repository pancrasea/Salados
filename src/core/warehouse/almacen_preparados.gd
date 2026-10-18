extends Node
class_name AlmacenPreparados

## Almacén compartido entre la Sección 2 (corte/desmenuce) y la Sección 3
## (preparación). Acumula las unidades de cada ingrediente ya preparado y
## notifica a los suscriptores para que las fuentes de la Sección 3 se
## muestren o se oculten. La clave es el `item_id` del ItemData (estable en
## runtime), con `resource_path` como respaldo.
signal inventario_actualizado(item: ItemData, cantidad: int)

var _cantidades: Dictionary = {}


## Registra una unidad preparada. `item` debe venir de un `.tres` con
## `item_id` o `resource_path` para poder contarse.
func agregar(item: ItemData) -> void:
	var clave := _clave_de(item)
	if clave == "":
		push_warning("AlmacenPreparados: el ItemData no tiene item_id ni resource_path.")
		return
	var cantidad: int = int(_cantidades.get(clave, 0)) + 1
	_cantidades[clave] = cantidad
	inventario_actualizado.emit(item, cantidad)


## Consume una unidad (al usarla en la Sección 3). Devuelve true si había stock.
func consumir(item: ItemData) -> bool:
	var clave := _clave_de(item)
	if clave == "":
		return false
	var cantidad: int = int(_cantidades.get(clave, 0))
	if cantidad <= 0:
		return false
	cantidad -= 1
	if cantidad > 0:
		_cantidades[clave] = cantidad
	else:
		_cantidades.erase(clave)
	inventario_actualizado.emit(item, cantidad)
	return true


func cantidad_de(item: ItemData) -> int:
	var clave := _clave_de(item)
	if clave == "":
		return 0
	return int(_cantidades.get(clave, 0))


func total_preparados() -> int:
	var total: int = 0
	for valor in _cantidades.values():
		total += int(valor)
	return total


## Vacía el almacén (p. ej. al empezar un día nuevo).
func reset() -> void:
	_cantidades.clear()
	inventario_actualizado.emit(null, 0)


func _clave_de(item: ItemData) -> String:
	if item == null:
		return ""
	if item.item_id != "":
		return item.item_id
	return item.resource_path
