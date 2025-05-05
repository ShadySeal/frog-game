extends ProgressBar

@export var player: Player

func _ready():
	if player:
		player.charge_updated.connect(_on_charge_updated)
		_on_charge_updated(player.charge_percent)

func _on_charge_updated(percent: float) -> void:
	value = percent * 100
