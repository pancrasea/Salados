extends Node
class_name AlmacenPreparados

## Datos compartidos mientras el jugador alterna las secciones 2 y 3.
## Sin límite de unidades. Preparación y visualización no se acoplan.
signal inventario_actualizado(item: ItemData, cantidad: int)

var _cantidades: Dictionary = {}

func agregar(item: ItemData) -> void:
    if item == null or item.resource_path.is_empty():
        push_warning("AlmacenPreparados: se requiere un ItemData guardado como .tres")
        return
    var clave: String = item.resource_path
    var cantidad: int = int(_cantidades.get(clave, 0)) + 1
    _cantidades[clave] = cantidad
    inventario_actualizado.emit(item, cantidad)

func cantidad_de(item: ItemData) -> int:
    if item == null:
        return 0
    return int(_cantidades.get(item.resource_path, 0))

func total_preparados() -> int:
    var total: int = 0
    for valor in _cantidades.values():
        total += int(valor)
    return total
