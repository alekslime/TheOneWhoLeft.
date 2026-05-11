@tool
extends Node3D

# 4 draw calls for 2,474 trees. No Vector3 soup.
#
# SETUP:
#   1. Attach this script to a Node3D in your level.
#   2. Expand tree1.glb in the FileSystem panel (click the arrow).
#      Drag the Bark mesh   -> tree1_bark_mesh
#      Drag the Leaves mesh -> tree1_leaves_mesh
#      Repeat for tree2.glb.
#   3. Set scatter_origin to the center of your level ground.
#   4. Click "Regenerate Trees" in the Inspector.
#   5. Delete the old tree foliage node.

@export_group("Tree 1 (706 instances)")
@export var tree1_bark_mesh: Mesh
@export var tree1_leaves_mesh: Mesh

@export_group("Tree 2 (1768 instances)")
@export var tree2_bark_mesh: Mesh
@export var tree2_leaves_mesh: Mesh

@export_group("Scatter Settings")
@export var scatter_origin: Vector3 = Vector3(0, 0, 0)
# Half-extents matching your level ground (~162 x 343)
@export var scatter_size: Vector2 = Vector2(80, 170)
# Trees won't spawn within this radius of the origin (keeps gameplay area clear)
@export var clear_radius: float = 20.0
@export var scale_min: float = 2.2
@export var scale_max: float = 2.7
@export var visibility_range_end: float = 180.0

@export_tool_button("Regenerate Trees") var _btn = _build


func _ready() -> void:
	if not Engine.is_editor_hint():
		_build()


func _build() -> void:
	for c in get_children():
		c.queue_free()
	var t1 := _scatter(706)
	var t2 := _scatter(1768)
	if tree1_bark_mesh:   add_child(_make(tree1_bark_mesh,   t1))
	if tree1_leaves_mesh: add_child(_make(tree1_leaves_mesh, t1))
	if tree2_bark_mesh:   add_child(_make(tree2_bark_mesh,   t2))
	if tree2_leaves_mesh: add_child(_make(tree2_leaves_mesh, t2))


func _scatter(count: int) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	result.resize(count)
	for i in count:
		var pos := Vector3.ZERO
		while true:
			pos.x = scatter_origin.x + randf_range(-scatter_size.x, scatter_size.x)
			pos.z = scatter_origin.z + randf_range(-scatter_size.y, scatter_size.y)
			pos.y = scatter_origin.y
			if Vector2(pos.x - scatter_origin.x, pos.z - scatter_origin.z).length() >= clear_radius:
				break
		var s := randf_range(scale_min, scale_max)
		var b := Basis(Vector3.UP, randf_range(0.0, TAU)).scaled(Vector3.ONE * s)
		result[i] = Transform3D(b, pos)
	return result


func _make(mesh: Mesh, transforms: Array[Transform3D]) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.mesh = mesh
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.visibility_range_end = visibility_range_end
	mmi.visibility_range_end_margin = 20.0
	mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	return mmi
