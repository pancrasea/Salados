class_name OrderData extends Resource

## Un pedido concreto de un cliente: plato base + agregados opcionales.
## La identidad del pedido es su clave canónica (ver key()), no la referencia.
##
## Modelo de contenidos: la clave identifica el CONJUNTO de alimentos del
## plato armado. La zona de espera calcula su clave con key_of_contents().

## Plato base que debe estar en la entrega (ej. encebollado).
@export var base: ItemData
## Agregados que el cliente espera (chifle, limón, maíz tostado o jugo).
## El orden dentro de este array es irrelevante para la comparación.
@export var extras: Array[ItemData] = []


## Clave canónica de este pedido; se compara contra ItemData.recipe_key
## del plato armado.
func key() -> String:
	var contents: Array[ItemData] = []
	if base != null:
		contents.append(base)
	contents.append_array(extras)
	return key_of_contents(contents)


## Devuelve true si el ItemData entregado corresponde a este pedido.
## Los platos armados usan recipe_key; chifle y jugo también pueden servirse
## solos cuando son la base completa del pedido.
func matches(item: ItemData) -> bool:
	if item == null:
		return false
	if item.recipe_key != "":
		return item.recipe_key == key()
	return base != null and extras.is_empty() \
		and base.item_id in ["chifle", "jugo_naranja"] \
		and item.item_id == base.item_id


## Valor de venta del pedido: suma de los precios de los ítems que lo componen
## (plato base + extras). Lo usa CustomerSpawner para calcular el pago; los
## ítems con `price = 0` no aportan.
func price() -> int:
	var total: int = 0
	if base != null:
		total += base.price
	for extra in extras:
		if extra != null:
			total += extra.price
	return total


## Clave canónica de un conjunto de alimentos: ids únicos ordenados
## unidos por coma. El orden de agregado y las repeticiones no alteran la
## clave; [encebollado, pan, limón] y [limón, encebollado, pan] son el
## mismo plato. Se usa tanto para el pedido (base + extras) como para el
## contenido actual del plato armado.
static func key_of_contents(items: Array[ItemData]) -> String:
	var ids: Array[String] = []
	for item in items:
		if item == null:
			continue
		var id := _id_for(item)
		if id != "" and not ids.has(id):
			ids.append(id)
	ids.sort()
	return ",".join(ids)


## Comodín para construir la clave de un pedido base + extras sin crear
## el array a mano (delega en key_of_contents).
static func key_for(p_base: ItemData, p_extras: Array[ItemData]) -> String:
	var contents: Array[ItemData] = []
	if p_base != null:
		contents.append(p_base)
	contents.append_array(p_extras)
	return key_of_contents(contents)


## Identificador estable de un ítem. Se prefiere item_id porque resource_path
## se pierde al duplicar recursos en runtime (el plato armado duplica su ItemData).
static func _id_for(item: ItemData) -> String:
	if item.item_id != "":
		return item.item_id
	if item.resource_path != "":
		return item.resource_path
	return item.name
