extends Area3D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_fade_and_load()

func _fade_and_load() -> void:
	var fade = get_tree().get_root().find_child("FadeRect", true, false)
	if fade:
		var tween = create_tween()
		tween.tween_property(fade, "modulate:a", 1.0, 0.8)
		tween.tween_callback(func():
			get_tree().change_scene_to_file("res://scenes/Level2.tscn")
		)
