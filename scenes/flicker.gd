extends OmniLight3D

func _process(delta: float) -> void:
	light_energy = 1.5 + sin(Time.get_ticks_msec() * 0.003) * 0.2 + randf_range(-0.05, 0.05)
