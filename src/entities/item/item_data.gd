class_name ItemData extends Resource

@export var name: String
@export var icon: Texture2D
@export var max_quantity: int = 10

# Identificador estable para claves de recetas/pedidos en runtime.
# Preferible a resource_path porque este se pierde al duplicar el recurso
# (los platos contenedores duplican su ItemData para no mutar el .tres).
@export var item_id: String = ""

# Clave canónica de la combinación de ingredientes de un plato preparado
# (ver OrderData.key_for). Se asigna SOLO en runtime sobre una copia del
# recurso; nunca se configura en el editor.
var recipe_key: String = ""

# indica el siguiente elemento en el que se tranforma el item
# ej. Cebolla -> Cebolla cortada
@export var next_data_state: ItemData
# indica si es un plato o vaso que puede recibir items
@export var is_container: bool = false
# indica que es el pedido del cliente
@export var is_final_product: bool = false
