class_name ArmyView
extends Node2D
## Draws every squad: a tall nobori banner per squad, then its soldiers as
## cut-paper figures. Back row first, so the front row overlaps it.

## How far up the page the back row stands, to read as further away.
const BACK_ROW_LIFT := 13.0
const BACK_ROW_SCALE := 0.92
const SWAY_ANGLE := 0.025

## Size of every figure on screen. Bigger reads better on a phone.
@export var figure_size: float = 1.45

@export_group("Walking")
## Distance covered by one step, in field units. Steps follow distance walked,
## so feet never slide.
@export var stride_length: float = 9.0
## How high a soldier bobs with each step.
@export var stride_bob: float = 2.5
## Forward lean while marching, in radians.
@export var march_lean: float = 0.08

## How far between the last tick and the next we are (0 to 1). Set by main.
var alpha: float = 1.0

var battle: Battle
var _figures: Dictionary = {}  # Soldier -> SoldierFigure
var _draw_order: Array[Soldier] = []
var _time: float = 0.0


func show_battle(b: Battle) -> void:
	battle = b
	_figures.clear()
	for s in battle.soldiers:
		_figures[s] = SoldierFigure.new(s, battle.side_setup(s.side))
	_draw_order = battle.soldiers.duplicate()
	_draw_order.sort_custom(func(a: Soldier, c: Soldier) -> bool:
		return a.row > c.row if a.row != c.row else a.x < c.x)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if battle == null:
		return
	for squad in battle.squads:
		_draw_nobori(squad)
	for s in _draw_order:
		_draw_soldier(s)


func ground_y(x: float) -> float:
	return HillsideView.FIELD_HEIGHT - battle.terrain.height_at(x)


func _draw_soldier(s: Soldier) -> void:
	var fig: SoldierFigure = _figures[s]
	var depth := BACK_ROW_SCALE if s.row == 1 else 1.0
	var size := fig.scale * depth * figure_size
	var facing := Battle.facing(s.side)
	var lift := BACK_ROW_LIFT if s.row == 1 else 0.0
	var x := lerpf(s.prev_x, s.x, alpha)
	var angle := sin(_time * fig.sway_speed + fig.sway_phase) * SWAY_ANGLE
	var bob := 0.0
	if s.squad.moving:
		# Each step lifts the body; steps are tied to distance walked.
		var phase := (x * facing + fig.sway_phase * stride_length) / stride_length * PI
		bob = absf(sin(phase)) * stride_bob * size
		angle = facing * march_lean + sin(phase) * SWAY_ANGLE
	var xf := Transform2D(angle, Vector2(size * facing, size), 0.0,
		Vector2(x, ground_y(x) - lift + 1.0 - bob))
	PaperDraw.draw_figure(self, fig.shapes, fig.details, xf, 0.9)


func _draw_nobori(squad: Squad) -> void:
	# A tall squad banner just behind the squad, so you can find (and later tap) it.
	var side_def := battle.side_setup(squad.side)
	var facing := Battle.facing(squad.side)
	var base_x := lerpf(squad.prev_anchor_x, squad.anchor_x, alpha) - facing * 16.0
	var base := Vector2(base_x, ground_y(base_x) - BACK_ROW_LIFT - 2.0)
	var flutter := sin(_time * 1.4 + squad.index) * 1.5
	var top := base + Vector2(flutter, -100.0)
	var shapes: Array = []
	shapes.append([PaperDraw.stick(base, top, 2.2), SoldierFigure.WOOD])
	shapes.append([PaperDraw.stick(top, top + Vector2(facing * 15.0, 0), 2.0), SoldierFigure.WOOD])
	var flag := PackedVector2Array([
		top + Vector2(0, 2), top + Vector2(facing * 15.0, 2),
		top + Vector2(facing * 15.0 + flutter, 56), top + Vector2(flutter * 0.5, 56)])
	var colour := SoldierFigure.GOLD if squad.has_commander else side_def.banner_colour
	shapes.append([flag, colour])
	var mon_centre := top + Vector2(facing * 7.5 + flutter * 0.5, 15)
	shapes.append([PaperDraw.ellipse(mon_centre, Vector2(5, 5), 12), side_def.mon_colour])
	shapes.append([PaperDraw.ellipse(mon_centre, Vector2(2.2, 2.2), 8), colour])
	# Banner shapes are built at figure size 1 around the base, then scaled.
	var xf := Transform2D(0.0, Vector2(figure_size, figure_size), 0.0, base) \
		* Transform2D(0.0, -base)
	PaperDraw.draw_figure(self, shapes, [], xf, 0.9)
