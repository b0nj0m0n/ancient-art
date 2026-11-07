class_name HillsideView
extends Node2D
## The painted landscape: a woodblock sky, distant mountains, drifting gold
## clouds, mist bands and the battle hill, each a watercolour paper layer.
## Pure drawing. It reads the Terrain resource and never changes it.
## Lives under FieldView, which centres the field on screen.
## Colours follow docs/art.md, measured from the reference prints.

const FIELD_HEIGHT := 720.0
const EDGE_STEP := 10.0

const WASH := preload("res://shaders/wash.gdshader")
const SKY := preload("res://shaders/sky.gdshader")
const MIST := preload("res://shaders/mist.gdshader")
const GOLD_CLOUD := preload("res://shaders/gold_cloud.gdshader")
const NOISE := preload("res://art/generated/wash_noise.png")

@export var terrain: Terrain
## Seed for edge wobble and cloud shapes, so the look is stable.
@export var art_seed: int = 1584

@export_group("Distant mountains")
@export var far_body: Color = Color("97a3a1")
@export var far_edge: Color = Color("5d6d72")
@export_group("Middle hills")
@export var mid_body: Color = Color("6f8a80")
@export var mid_edge: Color = Color("48625c")
@export_group("Battle hill")
@export var near_body: Color = Color("aaa982")
@export var near_edge: Color = Color("5f6644")
@export_group("Mist and clouds")
@export var red_mist: Color = Color("d98b7a")
@export var cream_mist: Color = Color("e6d3ae")
@export_range(0, 10) var gold_cloud_count: int = 5
@export var cloud_drift_px_per_s: float = 2.5

var _clouds: Array[Node2D] = []
var _cloud_span := Vector2.ZERO


func _ready() -> void:
	get_viewport().size_changed.connect(_rebuild)
	_rebuild.call_deferred()


func _process(delta: float) -> void:
	# Gold clouds drift slowly to the left and wrap around.
	for c in _clouds:
		c.position.x -= cloud_drift_px_per_s * delta * (0.7 + 0.3 * c.get_meta("speed"))
		if c.position.x < _cloud_span.x:
			c.position.x += _cloud_span.y - _cloud_span.x


func _rebuild() -> void:
	if terrain == null:
		return
	for child in get_children():
		child.queue_free()
	_clouds.clear()
	var vis := get_viewport().get_visible_rect()
	var left := vis.position.x - global_position.x - 40.0
	var right := left + vis.size.x + 80.0
	var top := vis.position.y - global_position.y
	_add_sky(left, right, top)
	_add_wash(_far_height, left, right, far_body, far_edge, 30.0, 1.6, 0.55)
	_add_gold_clouds(left, right)
	_add_mist(_far_height, left, right, 70.0, red_mist, 0.55, 26.0)
	_add_wash(_mid_height, left, right, mid_body, mid_edge, 55.0, 2.0, 0.7)
	_add_mist(_mid_height, left, right, 40.0, cream_mist, 0.45, 30.0)
	_add_wash(terrain.height_at, left, right, near_body, near_edge, 40.0, 2.4, 0.85)


func _far_height(x: float) -> float:
	var w := terrain.field_width
	return 330.0 + 70.0 * sin(x / w * TAU * 1.3 + 0.6) + 35.0 * sin(x / w * TAU * 3.1)


func _mid_height(x: float) -> float:
	# A softened, raised echo of the battle hill, behind it.
	return terrain.height_at(x * 0.85 + 120.0) + 70.0 + 18.0 * sin(x / 90.0)


func _material(shader: Shader, params: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter("noise_tex", NOISE)
	for k in params:
		m.set_shader_parameter(k, params[k])
	return m


func _add_mesh(mesh: ArrayMesh, material: ShaderMaterial) -> MeshInstance2D:
	var node := MeshInstance2D.new()
	node.mesh = mesh
	node.material = material
	add_child(node)
	return node


func _edge(height_fn: Callable, left: float, right: float, salt: int) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = art_seed + salt
	var pts := PackedVector2Array()
	var x := left
	while x <= right + EDGE_STEP:
		pts.append(Vector2(x, FIELD_HEIGHT - height_fn.call(x) + rng.randf_range(-0.8, 0.8)))
		x += EDGE_STEP
	return pts


func _add_sky(left: float, right: float, top: float) -> void:
	var t := PackedVector2Array([Vector2(left, top), Vector2(right, top)])
	var b := PackedVector2Array([Vector2(left, FIELD_HEIGHT), Vector2(right, FIELD_HEIGHT)])
	var mesh := _strip(t, b, func(i: int, is_top: bool) -> Vector2:
		var p := t[i] if is_top else b[i]
		return Vector2(p.x, p.y))
	_add_mesh(mesh, _material(SKY, {
		"screen_top": top,
		"glow_y": FIELD_HEIGHT - 330.0,
	}))


func _add_wash(height_fn: Callable, left: float, right: float, body: Color, edge: Color,
		fade_px: float, ink_px: float, ink_strength: float) -> void:
	var t := _edge(height_fn, left, right, int(fade_px))
	var b := PackedVector2Array()
	for p in t:
		b.append(Vector2(p.x, FIELD_HEIGHT + 60.0))
	# UV.y is the depth below the cut edge: 0 on the edge, the full height at the bottom.
	var mesh := _strip(t, b, func(i: int, is_top: bool) -> Vector2:
		return Vector2(t[i].x, 0.0 if is_top else b[i].y - t[i].y))
	_add_mesh(mesh, _material(WASH, {
		"body_colour": body, "edge_colour": edge, "fade_px": fade_px,
		"ink_px": ink_px, "ink_strength": ink_strength,
	}))


func _add_mist(height_fn: Callable, left: float, right: float, thickness: float,
		tint: Color, strength: float, drop: float) -> void:
	# A band whose top edge follows the land a little below its cut edge.
	var t := PackedVector2Array()
	var b := PackedVector2Array()
	var x := left
	while x <= right + EDGE_STEP:
		var y: float = FIELD_HEIGHT - height_fn.call(x) + drop + 8.0 * sin(x / 70.0 + drop)
		t.append(Vector2(x, y))
		b.append(Vector2(x, y + thickness))
		x += EDGE_STEP
	var mesh := _strip(t, b, func(i: int, is_top: bool) -> Vector2:
		return Vector2(t[i].x, 0.0 if is_top else 1.0))
	_add_mesh(mesh, _material(MIST, {"tint": tint, "strength": strength}))


func _add_gold_clouds(left: float, right: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = art_seed + 404
	_cloud_span = Vector2(left - 260.0, right + 260.0)
	var step: float = (_cloud_span.y - _cloud_span.x) / maxi(gold_cloud_count, 1)
	for i in gold_cloud_count:
		var size := Vector2(rng.randf_range(220.0, 380.0), rng.randf_range(34.0, 52.0))
		var node := _add_mesh(_cloud_mesh(size, rng), _material(GOLD_CLOUD, {}))
		node.position = Vector2(_cloud_span.x + step * (i + rng.randf_range(0.1, 0.9)),
			rng.randf_range(270.0, 330.0) + (i % 2) * 70.0)
		node.set_meta("speed", rng.randf())
		_clouds.append(node)


## A scalloped cloud outline, filled as a fan from its centre.
func _cloud_mesh(size: Vector2, rng: RandomNumberGenerator) -> ArrayMesh:
	var lobes := rng.randi_range(7, 10)
	var verts := PackedVector2Array([Vector2.ZERO])
	var uvs := PackedVector2Array([Vector2(0, 1)])
	var n := 96
	for i in n:
		var a := TAU * i / n
		var lobe := pow(abs(sin(a * lobes * 0.5)), 0.6)
		var upper := sin(a) < 0.0  # y points down, so negative is the top edge
		# Scalloped top, flatter and calmer bottom, like the clouds on a folding screen.
		var r := (0.78 + 0.22 * lobe) if upper else (0.95 + 0.05 * lobe)
		var squash := 1.0 if upper else 0.55
		verts.append(Vector2(cos(a) * size.x * r, sin(a) * size.y * r * squash))
		uvs.append(Vector2(0, 0))
	var idx := PackedInt32Array()
	for i in n:
		idx.append_array([0, 1 + i, 1 + (i + 1) % n])
	return _mesh(verts, uvs, idx)


## A strip between two matching rows of points. uv_fn(index, is_top) gives each UV.
func _strip(top_pts: PackedVector2Array, bottom_pts: PackedVector2Array, uv_fn: Callable) -> ArrayMesh:
	var n := top_pts.size()
	var verts := top_pts + bottom_pts
	var uvs := PackedVector2Array()
	for i in n:
		uvs.append(uv_fn.call(i, true))
	for i in n:
		uvs.append(uv_fn.call(i, false))
	var idx := PackedInt32Array()
	for i in n - 1:
		idx.append_array([i, i + 1, n + i, i + 1, n + i + 1, n + i])
	return _mesh(verts, uvs, idx)


func _mesh(verts: PackedVector2Array, uvs: PackedVector2Array, idx: PackedInt32Array) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
