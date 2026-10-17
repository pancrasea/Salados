class_name ItemData extends Resource

@export var name: String
@export var icon: Texture2D

# indica el siguiente elemento en el que se tranforma el item
# ej. Cebolla -> Cebolla cortada
@export var next_data_state: ItemData
# indica si es un plato o vaso que puede recibir items
@export var is_container: bool = false
# indica que es el pedido del cliente
@export var is_final_product: bool = false
