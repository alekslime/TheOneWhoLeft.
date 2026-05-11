extends Node

# Optimized gore manager. Three fixes applied:
#
# 1. CACHED TEXTURE — _create_blood_texture() used to run a 64x64 pixel loop
#    on every single blood splat. Now it runs once in _ready() and is reused forever.
#
# 2. ENFORCED DECAL CAP — MAX_DECALS was defined but never checked.
#    Old decals are now freed immediately when the cap is hit (FIFO eviction).
#
# 3. VARIED SPLATS — We pre-bake a small pool of slightly different textures
#    at startup so every splat doesn't look identical, with zero runtime cost.

const MAX_DECALS := 50
const SPLAT_VARIANTS := 6   # how many different textures to pre-bake
const SPLAT_SIZE := 64

var _decals: Array[Decal] = []
var _textures: Array[ImageTexture] = []


func _ready() -> void:
	for i in SPLAT_VARIANTS:
		_textures.append(_create_blood_texture())


func spawn_blood(pos: Vector3, normal: Vector3, parent: Node) -> void:
	# Enforce cap: evict oldest decal if we're at the limit
	if _decals.size() >= MAX_DECALS:
		var oldest: Decal = _decals.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()

	var decal := Decal.new()

	# Attach the cached texture (random variant)
	decal.texture_albedo = _textures[randi() % SPLAT_VARIANTS]

	# Size the decal — adjust to taste
	decal.size = Vector3(0.6, 0.6, 0.3)
	decal.upper_fade = 0.1
	decal.lower_fade = 0.05

	parent.add_child(decal)
	decal.global_position = pos + normal * 0.01

	var up := Vector3.FORWARD if normal.is_equal_approx(Vector3.UP) or normal.is_equal_approx(Vector3.DOWN) else Vector3.UP
	decal.look_at(pos - normal, up)

	# Random Z rotation so splats don't all face the same way
	decal.rotate_object_local(normal, randf_range(0.0, TAU))

	_decals.append(decal)


# Called by gore_decal.gd's timer when a decal finishes fading out
# so it's removed from our tracking array too.
func untrack_decal(decal: Decal) -> void:
	_decals.erase(decal)


# Pre-bakes a randomized blood splat texture.
# Only called SPLAT_VARIANTS times at startup — never at runtime.
func _create_blood_texture() -> ImageTexture:
	var image := Image.create(SPLAT_SIZE, SPLAT_SIZE, false, Image.FORMAT_RGBA8)
	var center := Vector2(SPLAT_SIZE / 2.0, SPLAT_SIZE / 2.0)

	# Random radius and "jaggedness" per variant
	var base_radius: float = randf_range(SPLAT_SIZE * 0.28, SPLAT_SIZE * 0.42)

	for x in range(SPLAT_SIZE):
		for y in range(SPLAT_SIZE):
			var offset := Vector2(x, y) - center
			var dist := offset.length()
			# Add noise to edge so it looks organic rather than a perfect circle
			var angle := atan2(offset.y, offset.x)
			var noise_r := base_radius + sin(angle * randf_range(3.0, 7.0)) * randf_range(2.0, 6.0)
			if dist < noise_r:
				var alpha := (1.0 - (dist / noise_r) * 0.6) * randf_range(0.85, 1.0)
				var red := randf_range(0.35, 0.65)
				image.set_pixel(x, y, Color(red, 0.0, 0.0, alpha))

	return ImageTexture.create_from_image(image)
