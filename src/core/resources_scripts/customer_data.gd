extends Resource
class_name CustomerData

## Reusable configuration for one customer archetype or instance.
## Crea un .tres por arquetipo y asígnalo al pool de CustomerSpawner.

## Name shown by interfaces that display customer identity.
@export var display_name: String = "Cliente"
## Sprite que se muestra en el Visual del cliente. Si es null se conserva
## la textura que tenga la escena como fallback.
@export var texture: Texture2D
## Paciencia en segundos. 0 = usar `RunBalance.default_patience` (valor central
## de la partida); el arquetipo solo la define cuando necesita diferenciarse.
@export_range(0.0, 300.0, 1.0) var patience_seconds: float = 0.0
## Item definition that must be delivered to satisfy this order.
## Solo se usa en modo clásico (sin OrderData); en la demo se ignora.
@export var requested_item: ItemData
## Pago base cuando el cliente es atendido a tiempo (paciencia alta).
@export_range(0, 100000, 1) var reward: int = 10
## Porcentaje adicional sobre el pago base (propina fija por arquetipo).
## El multiplicador de paciencia se aplica encima de este total.
@export_range(0.0, 100.0, 0.5) var tip_percent: float = 0.0
