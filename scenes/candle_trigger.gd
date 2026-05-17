extends Area3D

@export var candle: Node3D  # drag the candle node here

func _ready() -> void:
	candle.visible = false
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		candle.visible = true
