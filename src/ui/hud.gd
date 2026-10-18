extends CanvasLayer

## HUD de juego: muestra el dinero actual y el tiempo restante del día.
## Se instancia en main.tscn como hijo permanente y se muestra/oculta
## junto con la sesión de juego.

@onready var money_label: Label = $MoneyLabel
@onready var timer_label: Label = $TimerLabel


func _ready() -> void:
	GameManager.money_changed.connect(_on_money_changed)
	GameManager.day_tick.connect(_on_day_tick)
	_on_money_changed(GameManager.money)


func _on_money_changed(new_amount: int) -> void:
	money_label.text = "$%d" % new_amount


func _on_day_tick(seconds_remaining: float) -> void:
	var mins: int = int(seconds_remaining) / 60
	var secs: int = int(seconds_remaining) % 60
	timer_label.text = "%d:%02d" % [mins, secs]
