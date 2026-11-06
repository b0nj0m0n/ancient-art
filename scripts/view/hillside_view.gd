class_name HillsideView
extends Node2D
## Draws the paper hillside: rice-paper background plus stacked cut-paper layers.
## Pure drawing. It reads the Terrain resource and never changes it.

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
	# Keep the field centred however wide the phone screen is.
	var vis := get_viewport().get_visible_rect()
	position.x = vis.position.x + (vis.size.x - terrain.field_width) * 0.5
	_build_fibres()
	queue_redraw()


func _draw() -> void:
	var vis := get_viewport().get_visible_rect()
	var left := vis.position.x - position.x - EDGE_STEP
	var right := left + vis.size.x + EDGE_STEP * 2.0
	draw_rect(Rect2(left, vis.position.y, right - left, vis.size.y), Palette.PAPER)
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
	draw_polyline(edge, colour.darkened(0.25), 2.0, true)


func _far_height(x: float) -> float:
	var w := terrain.field_width
	return 430.0 + 70.0 * sin(x / w * TAU * 1.3 + 0.6) + 35.0 * sin(x / w * TAU * 3.1)


func _mid_height(x: float) -> float:
	# A softened, raised echo of the battle hill, behind it.
	return terrain.height_at(x * 0.85 + 120.0) + 70.0 + 18.0 * sin(x / 90.0)


func _build_fibres() -> void:
	_fibres.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = art_seed
	var vis := get_viewport().get_visible_rect()
	for _i in 140:
		var start := Vector2(
			rng.randf_range(0.0, vis.size.x) + vis.position.x - position.x,
			rng.randf_range(0.0, vis.size.y))
		var line := PackedVector2Array([start])
		var dir := Vector2.from_angle(rng.randf_range(0.0, TAU))
		for _j in 3:
			dir = dir.rotated(rng.randf_range(-0.6, 0.6))
			line.append(line[-1] + dir * rng.randf_range(4.0, 12.0))
		_fibres.append(line)
