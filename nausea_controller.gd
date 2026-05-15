extends Node

@onready var player = get_tree().get_root().find_child("Player", true, false)
@onready var nausea_rect = get_tree().get_root().find_child("NauseaRect", true, false)

var trauma := 0.0
var max_trauma := 100.0
var build_rate := 15.0
var decay_rate := 20.0
var is_looking_at_gore := false
var time_offset := 0.0

# voice thresholds
var voice_low_played := false
var voice_mid_played := false
var voice_high_played := false

var look_away_timer := 0.0
const LOOK_AWAY_DELAY := 0.3


@onready var voice_low = get_tree().get_root().find_child("VoiceLow", true, false)
@onready var voice_mid = get_tree().get_root().find_child("VoiceMid", true, false)
@onready var voice_high = get_tree().get_root().find_child("VoiceHigh", true, false)

func _ready() -> void:
	print("NauseaController ready")
	print("Player: ", player)
	print("NauseaRect: ", nausea_rect)

func _process(delta: float) -> void:
	if not player:
		return
	
	time_offset += delta
	_check_gore_look()
	_update_trauma(delta)
	_update_shader()
	_handle_voices()

func _check_gore_look() -> void:
	var camera = player.get_node_or_null("Head/Camera3D")
	if not camera:
		return
	var space = player.get_world_3d().direct_space_state
	var origin = camera.global_position
	var target = origin + (-camera.global_transform.basis.z * 2.0)
	var query = PhysicsRayQueryParameters3D.create(origin, target)
	query.exclude = [player.get_rid()]
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result = space.intersect_ray(query)
	if result.has("collider"):
		print("Hit: ", result["collider"].name, " groups: ", result["collider"].get_groups())
	if result.has("collider") and result["collider"].is_in_group("gore"):
		is_looking_at_gore = true
	else:
		is_looking_at_gore = false


func _update_trauma(delta: float) -> void:
	if is_looking_at_gore:
		look_away_timer = 0.0
		trauma = min(trauma + build_rate * delta, max_trauma)
		if player:
			player.is_ads = true
	else:
		look_away_timer += delta
		if look_away_timer >= LOOK_AWAY_DELAY:
			var was_above_zero = trauma > 0.0
			trauma = max(trauma - decay_rate * delta, 0.0)
			if player:
				player.is_ads = false
			if was_above_zero and trauma <= 0.0:
				_fade_voices()

func _update_shader() -> void:
	if not nausea_rect:
		return
	var mat = nausea_rect.material
	if mat:
		mat.set_shader_parameter("intensity", trauma / max_trauma)
		mat.set_shader_parameter("time_offset", time_offset)

func _handle_voices() -> void:
	var t = trauma / max_trauma
	if t >= 0.2 and not voice_low_played:
		voice_low_played = true
		if voice_low:
			voice_low.play()
	if t >= 0.5 and not voice_mid_played:
		voice_mid_played = true
		if voice_mid:
			voice_mid.play()
	if t >= 0.9 and not voice_high_played:
		voice_high_played = true
		if voice_high:
			voice_high.play()

func _fade_voices() -> void:
	for v in [voice_low, voice_mid, voice_high]:
		if v and v.playing:
			var tween = create_tween()
			tween.tween_property(v, "volume_db", -80.0, 0.8)
			tween.tween_callback(func(): v.stop(); v.volume_db = 0.0)
	# reset flags so voices can retrigger
	voice_low_played = false
	voice_mid_played = false
	voice_high_played = false
