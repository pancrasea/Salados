extends Resource
class_name CustomerData

## Reusable configuration for one customer archetype or instance.

## Name shown by interfaces that display customer identity.
@export var display_name: String = "Cliente"
## Time available before this customer leaves without being served.
@export_range(1.0, 300.0, 1.0) var patience_seconds: float = 30.0
## Item definition that must be delivered to satisfy this order.
@export var requested_item: ItemData
## Base payment granted when the customer is served correctly.
@export_range(0, 100000, 1) var reward: int = 10
## Optional percentage added to the base reward.
@export_range(0.0, 100.0, 0.5) var tip_percent: float = 0.0
