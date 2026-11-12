class_name CommandBarView
extends Control
## The command bar as a single brush stroke: ink fills it as orders become
## available again. Small ink ticks mark each whole order. No numbers.

const STROKE_PAPER := Color(0.216, 0.212, 0.216, 0.18)
const STROKE_INK := Color("373637")
const REFUSE_RED := Color("c0453a")

var battle: Battle
var _refused_at: float = -10.0
var _time: float = 0.0


## Flash the bar: an order was given without enough in it.
func refuse() -> void:
	_refused_at = _time


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if battle == null:
		return
	var side := battle.setup.player_side
	var full := battle.tuning.command_bar_max
	var level := clampf(battle.command[side] / full, 0.0, 1.0)
	var r := Rect2(Vector2.ZERO, size)
	var shake := 0.0
	var since := _time - _refused_at
	if since < 0.45:
		shake = sin(since * 60.0) * 5.0 * (1.0 - since / 0.45)
	r.position.x += shake
	draw_colored_polygon(_stroke(r, 1.0), STROKE_PAPER)
	if level > 0.0:
		draw_colored_polygon(_stroke(r, level), STROKE_INK)
	# A tick at each whole order.
	var orders := int(full / battle.tuning.order_cost)
	for i in range(1, orders):
		var x := r.position.x + r.size.x * float(i) / orders
		draw_line(Vector2(x, r.position.y - 4.0), Vector2(x, r.end.y + 4.0), Palette.PAPER, 3.0)
	if since < 0.45:
		draw_polyline(_closed(_stroke(r, 1.0)), REFUSE_RED, 3.0)


## A brush stroke across the rect, filled to `fill` (0 to 1): a blunt start, a
## slightly wavering body and a tapering tail.
func _stroke(r: Rect2, fill: float) -> PackedVector2Array:
	var top := PackedVector2Array()
	var bottom := PackedVector2Array()
	var steps := 24
	var h := r.size.y
	for i in steps + 1:
		var t := float(i) / steps * fill
		var x := r.position.x + r.size.x * t
		var thick := h * (0.5 if t < 0.05 else 1.0) * (1.0 - smoothstep(0.85, 1.0, t) * 0.8)
		var wave := sin(t * 11.0) * h * 0.06
		var mid := r.position.y + h * 0.5 + wave
		top.append(Vector2(x, mid - thick * 0.5))
		bottom.append(Vector2(x, mid + thick * 0.5))
	bottom.reverse()
	return top + bottom


func _closed(p: PackedVector2Array) -> PackedVector2Array:
	var c := p.duplicate()
	c.append(p[0])
	return c
