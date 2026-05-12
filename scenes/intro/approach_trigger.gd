extends Area3D

var played: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and not played:
		played = true
		var audio = get_tree().get_root().find_child("Level1", true, false)
		if audio:
			audio.trigger_wife()
