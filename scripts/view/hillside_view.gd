class_name HillsideView
extends Node2D
## Draws the paper hillside: rice-paper background plus stacked cut-paper layers.
## Pure drawing. It reads the Terrain resource and never changes it.
## Lives under FieldView, which centres the field on screen.

@export var terrain: Terrain
## Seed for the paper fibres and ragged cut edges, so the look is stable.
@export var art_seed: int = 1584

const FIELD_HEIGHT := 720.0
const EDGE_STEP := 16.0
const SHADOW_OFFSET := Vector2(4, 6)

var _fibres: Array[PackedVector2Array] = []


func _ready() -> void:
	get_viewport().size_changed.connect(_on_resized)
	_on_resized()


func _on_resized() -> void:
	_build_fibres()
	queue_redraw()


func _draw() -> void:
	var vis := get_viewport().get_visible_rect()
	var left := vis.position.x - global_position.x - EDGE_STEP
	var right := left + vis.size.x + EDGE_STEP * 2.0
	draw_rect(Rect2(left, vis.position.y - global_position.y, right - left, vis.size.y), Palette.PAPER)
	for fibre in _fibres:
		draw_polyline(fibre, Palette.PAPER_FIBRE, 1.0)
	_draw_layer(_far_height, left, right, Palette.FAR_MOUNTAIN, 11)
	_draw_layer(_mid_height, left, right, Palette.MID_HILL, 23)
	_draw_layer(terrain.height_at, left, right, Palette.NEAR_GROUND, 37)


## One cut-paper layer: a soft shadow, the paper fill, then an inked edge.
func _draw_layer(height_fn: Callable, left: float, right: float, colour: Color, edge_seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = art_seed + edge_seed
	var edge := PackedVector2Array()
	var x := left
	while x <= right:
		var jitter := rng.randf_range(-1.5, 1.5)
		edge.append(Vector2(x, FIELD_HEIGHT - height_fn.call(x) + jitter))
		x += EDGE_STEP
	var shape := edge.duplicate()
	shape.append(Vector2(right, FIELD_HEIGHT + 40.0))
	shape.append(Vector2(left, FIELD_HEIGHT + 40.0))
	var shadow := PackedVector2Array()
	for p in shape:
		shadow.append(p + SHADOW_OFFSET)
	draw_colored_polygon(shadow, Palette.CUT_SHADOW)
	draw_colored_polygon(shape, colour)
	# Watercolour wash: pigment pooling just under the cut edge.
	for band in [[10.0, 18.0, 0.10], [26.0, 22.0, 0.05]]:
		var wash := PackedVector2Array()
		for p in edge:
			wash.append(p + Vector2(0, band[0]))
		var tint := colour.darkened(0.3)
		tint.a = band[2]
		draw_polyline(wash, tint, band[1], true)
	draw_polyline(edge, colour.darkened(0.25), 2.0, true)


func _far_height(x: float) -> float:
	var w := terrain.field_width
	return 430.0 + 70.0 * sin(x / w * TAU * 1.3 + 0.6) + 35.0 * sin(x / w * TAU * 3.1)


func _mid_height(x: float) -> float:
	# A softened, raised echo of the battle hill, behind it.
	return terrain.height_at(x * 0.85 + 120.0) + 70.0 + 18.0 * sin(x / 90.0)


func _build_fibres() -> void:
	# Fibres cover a wide band around the field, so they never depend on screen size.
	_fibres.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = art_seed
	var w := terrain.field_width if terrain else 1280.0
	for _i in 220:
		var start := Vector2(rng.randf_range(-500.0, w + 500.0), rng.randf_range(0.0, FIELD_HEIGHT))
		var line := PackedVector2Array([start])
		var dir := Vector2.from_angle(rng.randf_range(0.0, TAU))
		for _j in 3:
			dir = dir.rotated(rng.randf_range(-0.6, 0.6))
			line.append(line[-1] + dir * rng.randf_range(4.0, 12.0))
		_fibres.append(line)
