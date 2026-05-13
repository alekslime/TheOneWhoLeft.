extends Node3D

@onready var music_warm = $IntroAudio/MusicWarm
@onready var music_eerie = $IntroAudio/MusicEerie
@onready var music_classical = $IntroAudio/MusicClassical
@onready var ambient_outside = $IntroAudio/AmbientOutside
@onready var voice_wife = $IntroAudio/VoiceWife
@onready var voice_mysterious = $IntroAudio/VoiceMysterious	

var outside_triggered: bool = false

func _ready() -> void:
	music_warm.play()
	ambient_outside.play()
	# hide sigils at start
	var sigils = get_node_or_null("Sigils")
	if sigils:
		sigils.visible = false

func trigger_wife() -> void:
	voice_wife.play()

func trigger_inside() -> void:
	_fade_out(music_warm, 1.5)
	_fade_out(ambient_outside, 1.5)
	_fade_out_3d(voice_wife, 0.5)
	music_eerie.play()
	await get_tree().create_timer(7.0).timeout
	voice_mysterious.play()

func trigger_outside() -> void:
	if outside_triggered:
		return
	outside_triggered = true
	_fade_out(music_eerie, 1.0)
	music_classical.play()
	# show sigils and start cult hum
	var sigils = get_node_or_null("Sigils")
	if sigils:
		sigils.visible = true
	var hum = get_node_or_null("IntroAudio/CultHum")
	if hum:
		hum.play()

func _fade_out(player: AudioStreamPlayer, duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(player, "volume_db", -80.0, duration)
	tween.tween_callback(func(): player.stop())

func _fade_out_3d(player: AudioStreamPlayer3D, duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(player, "volume_db", -80.0, duration)
	tween.tween_callback(func(): player.stop())
