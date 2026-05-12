extends CharacterBody3D

# --- NODES ---
@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var hud = get_tree().current_scene.get_node_or_null("HUD")
@onready var footstep_sound: AudioStreamPlayer = $FootstepSound
@onready var rage_activate_sound: AudioStreamPlayer = $RageActivateSound
@onready var rage_breathing_sound: AudioStreamPlayer = $RageBreathingSound
@onready var hit_sound: AudioStreamPlayer = $HitSound
@onready var death_sound: AudioStreamPlayer = $DeathSound

var weapon_manager = null
var footstep_timer := 0.0
var is_dead := false
var time_scale_target := 1.0
var current_audio_pitch := 1.0

# --- HEALTH ---
var max_health: float = 100.0
var current_health: float = 100.0

# --- SPEED ---
const WALK_SPEED = 4.5
const SPRINT_SPEED = 7.5
const JUMP_VELOCITY = 7.0
const GRAVITY = 20.0

# --- ACCELERATION ---
const ACCEL_GROUND = 10.0
const ACCEL_AIR = 3.0
const FRICTION = 8.0
const AIR_FRICTION = 0.5

# --- MOUSE LOOK ---
var MOUSE_SENSITIVITY = 0.002
var pitch := 0.0

# --- CAMERA BOB ---
const BOB_FREQUENCY_WALK = 6.0
const BOB_FREQUENCY_SPRINT = 9.0
const BOB_AMPLITUDE_WALK = 0.03
const BOB_AMPLITUDE_SPRINT = 0.05
var bob_timer := 0.0
var default_camera_y := 0.0

# --- CAMERA FOV ---
const FOV_DEFAULT = 90.0
const FOV_SPRINT = 93.0
const FOV_SPEED = 6.0
const FOV_ADS_MULTIPLIER := 0.65
var is_ads := false

# --- STATE ---
var current_speed := WALK_SPEED

# --- SCREEN SHAKE ---
const SHAKE_DECAY = 5.0
var shake_intensity := 0.0

# --- LANDING BOB ---
var was_in_air := false
var land_bob_timer := 0.0
const LAND_BOB_DURATION := 0.18
const LAND_BOB_AMOUNT := 0.08

# --- RAGE ---
const RAGE_PER_KILL = 25.0
const RAGE_PER_DAMAGE = 0.8
const RAGE_DURATION = 8.0
const RAGE_SPEED_MULTIPLIER = 1.4
const RAGE_DAMAGE_MULTIPLIER = 1.5
var rage := 0.0
var is_raging := false
var rage_timer := 0.0
var rage_vignette_alpha := 0.0


func _ready() -> void:
	weapon_manager = $Head/Camera3D/WeaponHolder
	if weapon_manager == null:
		push_error("WeaponHolder not found!")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	default_camera_y = camera.position.y


func _input(event: InputEvent) -> void:
	if is_dead:
		return
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		pitch = clamp(pitch - event.relative.y * MOUSE_SENSITIVITY, -1.4, 1.4)
		head.rotation.x = pitch
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _process(delta: float) -> void:
	Engine.time_scale = lerp(Engine.time_scale, time_scale_target, 0.05)
	current_audio_pitch = lerp(current_audio_pitch, time_scale_target, 0.08)
	footstep_sound.pitch_scale = current_audio_pitch
	rage_breathing_sound.pitch_scale = current_audio_pitch
	rage_activate_sound.pitch_scale = current_audio_pitch


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_handle_gravity(delta)
	_handle_movement(delta)
	_handle_jump()
	_handle_camera(delta)
	_handle_rage(delta)
	_handle_footsteps(delta)
	_handle_ads_input()
	if weapon_manager:
		weapon_manager.handle_input(delta)
	move_and_slide()


func _handle_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta


func _handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY


func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if Input.is_action_pressed("sprint"):
		current_speed = SPRINT_SPEED
	else:
		current_speed = WALK_SPEED
	var rage_boost = RAGE_SPEED_MULTIPLIER if is_raging else 1.0
	var effective_speed = current_speed * rage_boost
	var accel = ACCEL_GROUND if is_on_floor() else ACCEL_AIR
	var friction = FRICTION if is_on_floor() else AIR_FRICTION
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * effective_speed, accel * effective_speed * delta)
		velocity.z = move_toward(velocity.z, direction.z * effective_speed, accel * effective_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * effective_speed * delta)
		velocity.z = move_toward(velocity.z, 0.0, friction * effective_speed * delta)


func _handle_camera(delta: float) -> void:
	_handle_camera_bob(delta)
	_handle_camera_fov(delta)
	_handle_screen_shake(delta)
	_handle_landing_bob(delta)


func _handle_camera_bob(delta: float) -> void:
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	var speed = horizontal_velocity.length()
	if is_on_floor() and speed > 0.5:
		var freq = BOB_FREQUENCY_SPRINT if Input.is_action_pressed("sprint") else BOB_FREQUENCY_WALK
		var amp = BOB_AMPLITUDE_SPRINT if Input.is_action_pressed("sprint") else BOB_AMPLITUDE_WALK
		bob_timer += delta * freq
		camera.position.y = default_camera_y + sin(bob_timer) * amp
	else:
		bob_timer = 0.0
		camera.position.y = lerp(camera.position.y, default_camera_y, delta * 10.0)


func _handle_camera_fov(delta: float) -> void:
	var target_fov: float
	if is_ads:
		target_fov = FOV_DEFAULT * FOV_ADS_MULTIPLIER
	elif Input.is_action_pressed("sprint"):
		target_fov = FOV_SPRINT
	else:
		target_fov = FOV_DEFAULT
	camera.fov = lerp(camera.fov, target_fov, delta * FOV_SPEED)


func take_damage(amount: float) -> void:
	if is_dead:
		return
	current_health -= amount
	shake(0.06)
	if weapon_manager and weapon_manager.current_weapon:
		if weapon_manager.current_weapon.has_method("on_player_damaged"):
			weapon_manager.current_weapon.on_player_damaged()
	if hit_sound and not hit_sound.playing:
		hit_sound.pitch_scale = randf_range(0.9, 1.1)
		hit_sound.play()
	if hud:
		hud.update_health(current_health, max_health)
		hud.flash_damage()
	if current_health <= 0:
		die()


func die() -> void:
	if is_dead:
		return
	is_dead = true
	current_health = 0
	shake(0.45)
	Engine.time_scale = 0.12
	await get_tree().create_timer(0.4).timeout
	Engine.time_scale = 1.0
	if death_sound:
		death_sound.play()
	if hud:
		hud.update_health(0, max_health)
		hud.show_death_screen()
	velocity = Vector3.ZERO
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if weapon_manager and weapon_manager.current_weapon:
		weapon_manager.current_weapon.can_fire = false
	footstep_sound.stop()
	rage_breathing_sound.stop()


func shake(intensity: float) -> void:
	shake_intensity = intensity


func _handle_screen_shake(delta: float) -> void:
	if shake_intensity > 0:
		shake_intensity = lerp(shake_intensity, 0.0, SHAKE_DECAY * delta)
		camera.position.x = randf_range(-shake_intensity, shake_intensity)
		camera.position.y = default_camera_y + randf_range(-shake_intensity, shake_intensity)
	else:
		camera.position.x = lerp(camera.position.x, 0.0, delta * 10.0)


func _handle_landing_bob(delta: float) -> void:
	var on_floor = is_on_floor()
	if was_in_air and on_floor:
		land_bob_timer = LAND_BOB_DURATION
		shake(0.02)
		if weapon_manager and weapon_manager.current_weapon:
			if weapon_manager.current_weapon.has_method("on_player_land"):
				weapon_manager.current_weapon.on_player_land(1.0)
	was_in_air = not on_floor
	if land_bob_timer > 0:
		land_bob_timer -= delta
		var t = 1.0 - (land_bob_timer / LAND_BOB_DURATION)
		var bob = sin(t * PI) * LAND_BOB_AMOUNT
		camera.position.y = default_camera_y - bob


func _handle_footsteps(delta: float) -> void:
	var on_floor = is_on_floor()
	var speed = Vector3(velocity.x, 0, velocity.z).length()
	if on_floor and speed > 1.0:
		var interval = 0.5 if not Input.is_action_pressed("sprint") else 0.35
		footstep_timer -= delta
		if footstep_timer <= 0:
			footstep_sound.play()
			footstep_timer = interval
	else:
		footstep_timer = 0.1


func add_rage(amount: float) -> void:
	rage = min(rage + amount, 100.0)
	if hud:
		hud.update_rage(rage)


func _activate_rage() -> void:
	is_raging = true
	rage_timer = RAGE_DURATION
	shake(0.08)
	if hud:
		hud.flash_damage()
	rage_activate_sound.play()
	rage_breathing_sound.play()
	time_scale_target = 0.4


func _handle_rage(delta: float) -> void:
	if Input.is_action_just_pressed("rage") and rage >= 100.0 and not is_raging:
		_activate_rage()
	if is_raging:
		rage_timer -= delta / Engine.time_scale
		rage_vignette_alpha = 0.2 + sin(rage_timer * 4.0) * 0.08
		if hud:
			hud.set_rage_vignette(rage_vignette_alpha)
			hud.update_rage(rage_timer / RAGE_DURATION * 100.0)
		if rage_timer <= 0:
			is_raging = false
			rage = 0.0
			rage_vignette_alpha = 0.0
			rage_breathing_sound.stop()
			time_scale_target = 1.0
			if hud:
				hud.set_rage_vignette(0.0)
				hud.update_rage(0.0)


func heal(amount: float) -> void:
	if is_dead:
		return
	current_health = min(current_health + amount, max_health)
	if hud:
		hud.update_health(current_health, max_health)
		hud.flash_heal()


func _handle_ads_input() -> void:
	var wm = weapon_manager
	if not wm or not wm.get("current_weapon"):
		return
	var weapon = wm.current_weapon
	if weapon.weapon_name == "The Flame":
		return
	if Input.is_action_just_pressed("ads"):
		is_ads = true
		weapon.start_ads()
	elif Input.is_action_just_released("ads"):
		is_ads = false
		weapon.stop_ads()
	if is_ads and not Input.is_action_pressed("ads"):
		is_ads = false
		weapon.stop_ads()
