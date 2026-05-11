extends Decal

# Optimized: zero per-frame cost.
# Old version ran _process(delta) 60x/sec on every active decal just to count time.
# This version fires a one-shot timer and frees itself — no tick overhead at all.

const LIFETIME := 30.0
const FADE_DURATION := 3.0


func _ready() -> void:
	var fade_start := LIFETIME - FADE_DURATION
	await get_tree().create_timer(fade_start).timeout
	_fade_out()


func _fade_out() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	await tween.finished
	queue_free()
