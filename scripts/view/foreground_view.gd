class_name ForegroundView
extends Node2D
## The front paper layer: a strip of nearer ground along the bottom of the
## screen with grass tufts. It sits in front of the battle for depth, but low
## enough that it never hides a soldier.

## Height of the strip's top edge above the bottom of the field.
@export var strip_height: float = 52.0
@export var art_seed: int = 77

const GREEN := Color("62744f")
const TUFT := Color("47553a")


func _ready() -> void:
	get_viewport().size_changed.connect(queue_redraw)


func _draw() -> void:
	var vis := get_viewport().get_visible_rect()
	var left := vis.position.x - global_position.x - 20.0
	var right := left + vis.size.x + 40.0
	var bottom := HillsideView.FIELD_HEIGHT + 40.0
	var rng := RandomNumberGenerator.new()
	rng.seed = art_seed
	var edge := PackedVector2Array()
	var x := left
	while x <= right:
		var y := HillsideView.FIELD_HEIGHT - strip_height + sin(x / 140.0) * 8.0 + rng.randf_range(-1.5, 1.5)
		edge.append(Vector2(x, y))
		x += 18.0
	var shape := edge.duplicate()
	shape.append(Vector2(right, bottom))
	shape.append(Vector2(left, bottom))
	var shapes: Array = [[shape, GREEN]]
	# Grass tufts: three paper blades each, standing on the strip's edge.
	for i in range(1, edge.size() - 1, 3):
		var base := edge[i] + Vector2(rng.randf_range(-6.0, 6.0), 3.0)
		var h := rng.randf_range(10.0, 20.0)
		for lean in [-5.0, 0.0, 5.0]:
			var tip := base + Vector2(lean + rng.randf_range(-2.0, 2.0), -h * (0.7 if lean != 0.0 else 1.0))
			shapes.append([PackedVector2Array([base + Vector2(-2, 0), tip, base + Vector2(2, 0)]), TUFT])
	PaperDraw.draw_figure(self, shapes, [], Transform2D.IDENTITY, 1.8)
