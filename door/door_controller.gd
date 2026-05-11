extends Node3D
@export var open_angle: float = -100.0
@export var open_duration: float = 0.9
@export var close_duration: float = 0.9
@export var door_mesh: Node3D
@export var creak_sound: AudioStreamPlayer3D = null

var is_open: bool = false
var is_animating: bool = false
var tween: Tween = null
var cursed_env = preload("res://environment.tres")

func _ready() -> void:
	if has_node("TriggerArea"):
		$TriggerArea.body_entered.connect(_on_player_entered_outside)
		$TriggerArea.body_exited.connect(_on_player_exited_outside)
	if has_node("InnerTrigger"):
		$InnerTrigger.monitoring = false  # disabled until player is inside
		$InnerTrigger.body_exited.connect(_on_player_exited_inside)

func _on_player_entered_outside(body: Node) -> void:
	if body.is_in_group("player") and not is_open:
		_animate(open_angle, open_duration)
		is_open = true

func _on_player_exited_outside(body: Node) -> void:
	if body.is_in_group("player"):
		if is_open:
			_trigger_transformation()  # ← swaps environment as you pass through
		else:
			_animate(0.0, close_duration)

func _on_player_exited_inside(body: Node) -> void:
	if body.is_in_group("player"):
		# player is walking back out
		_trigger_transformation()
		_animate(open_angle, open_duration)
		is_open = true
		$InnerTrigger.monitoring = false  # reset for safety

func _trigger_transformation() -> void:
	var world_env = get_tree().get_root().find_child("WorldEnvironment", true, false)
	if world_env:
		world_env.environment = cursed_env

func _animate(target_angle: float, duration: float) -> void:
	if tween and tween.is_valid():
		tween.kill()
	if creak_sound:
		creak_sound.play()
	is_animating = true
	tween = get_tree().create_tween()
	tween.tween_property(
		door_mesh,
		"rotation_degrees:y",
		target_angle,
		duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): is_animating = false)
