extends MeshInstance3D
## Attach to each eye-bulge MeshInstance3D in the corridor.
## Mirrors the pattern you already use in candle_trigger.gd -- a trigger
## area drives visible state, except here it drives shader params over time
## instead of toggling .visible.

@export var player: Node3D                  # drag the player node here (or auto-find below)
@export var open_speed: float = 0.6         # how fast the eye opens/closes per second
@export var track_speed: float = 3.0        # how fast the pupil catches up to look direction
@export var max_pupil_offset: float = 0.4   # clamp so the pupil doesn't clip out of the iris
@export var wake_when_looked_at: bool = true

var _target_open: float = 0.0
var _current_open: float = 0.0
var _current_pupil: Vector2 = Vector2.ZERO
var _mat: ShaderMaterial


func _ready() -> void:
	_mat = get_active_material(0) as ShaderMaterial
	if _mat == null:
		push_warning("EyeController: surface 0 has no ShaderMaterial using eye_wall.gdshader")
	if player == null:
		# Same lookup convention as door_controller.gd's _get_audio()
		player = get_tree().get_root().find_child("Player", true, false)


func _process(delta: float) -> void:
	if _mat == null:
		return

	if player:
		var to_player := global_transform.origin.direction_to(player.global_transform.origin)
		var local_dir := global_transform.basis.inverse() * to_player
		# Project onto this eye's local XY plane to get a 2D "look" vector
		var look2d := Vector2(local_dir.x, local_dir.y).limit_length(max_pupil_offset)
		_current_pupil = _current_pupil.lerp(look2d, delta * track_speed)
		_mat.set_shader_parameter("pupil_offset", _current_pupil)

		if wake_when_looked_at:
			# Player is "looking toward the door" == moving/facing away from this eye,
			# which is the inversion described in the design: looking toward the goal
			# wakes the horror, not looking away from it.
			var player_forward := -player.global_transform.basis.z
			var facing_away_from_eye := player_forward.dot(-to_player) > 0.3
			_target_open = 1.0 if facing_away_from_eye else 0.15

	_current_open = move_toward(_current_open, _target_open, delta * open_speed)
	_mat.set_shader_parameter("open_amount", _current_open)


## Call this from a trigger area (same pattern as CandleTrigger1 nodes)
## to force this eye fully open regardless of look direction -- e.g. for a
## scripted beat near the final door.
func force_open() -> void:
	_target_open = 1.0


func force_closed() -> void:
	_target_open = 0.0


## Feeds the vein/bloodshot intensity. Wire this to your GameManager's
## fear/guilt tracking if you have one, or to time-spent-hesitating.
func set_stress(value: float) -> void:
	if _mat:
		_mat.set_shader_parameter("stress", clamp(value, 0.0, 1.0))
