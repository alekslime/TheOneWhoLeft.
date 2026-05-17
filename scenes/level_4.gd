extends Node3D

func _ready() -> void:
	var fade = get_node_or_null("CanvasLayer/FadeRect")
	if fade:
		var tween = create_tween()
		tween.tween_property(fade, "modulate:a", 0.0, 1.0)
