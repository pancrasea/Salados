class_name OrderData extends Resource

## Un pedido concreto de un cliente: plato base + agregados opcionales.
## La identidad del pedido es su clave canónica (ver key()), no la referencia.
##
## Modelo de contenidos: la clave identifica el CONJUNTO de alimentos que
## deben estar dentro de la bandeja. El jugador agrega a la bandeja el
## plato de encebollado (base) y los extras del pedido; la bandeja calcula
## su clave con OrderData.key_of_contents() y se compara con la del pedido.

## Plato base que debe ir sí o sí en la bandeja (ej. encebollado).
@export var base: ItemData
## Agregados que el cliente espera (pan, chifle, limón, canguil, maíz tostado).
## El orden dentro de este array es irrelevante para la comparación.
@export var extras: Array[ItemData] = []


## Clave canónica de este pedido; se compara contra ItemData.recipe_key
## de la bandeja preparada.
func key() -> String:
	var contents: Array[ItemData] = []
	if base != null:
		contents.append(base)
	contents.append_array(extras)
	return key_of_contents(contents)


## Devuelve true si el ItemData entregado corresponde a este pedido.
## Exige que el ítem tenga recipe_key asignado: en la práctica solo la
## tiene la bandeja (contenedor) tras recibir alimentos en _ready o
## collect_ingredients. Entregar un alimento suelto al cliente con pedido
## estructurado siempre se rechaza; hay que usar la bandeja.
func matches(item: ItemData) -> bool:
	return item != null and item.recipe_key != "" and item.recipe_key == key()


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
## contenido actual de la bandeja.
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
## se pierde al duplicar recursos en runtime (la bandeja duplica su ItemData).
static func _id_for(item: ItemData) -> String:
	if item.item_id != "":
		return item.item_id
	if item.resource_path != "":
		return item.resource_path
	return item.name
