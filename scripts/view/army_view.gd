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
## Animations rigged figures play (names from their rig.json).
@export var rigged_walk_animation: String = "walk"
@export var rigged_rest_animation: String = "idle"

@export_group("Walking")
## Distance covered by one step, in field units. Steps follow distance walked,
## so feet never slide.
@export var stride_length: float = 9.0
## How high a soldier bobs with each step.
@export var stride_bob: float = 2.5
## Forward lean while marching, in radians.
@export var march_lean: float = 0.08

@export_group("Fighting")
## Seconds a strike, a flinch from a blow, and a fall take to play.
@export var strike_seconds: float = 0.4
@export var flinch_seconds: float = 0.35
@export var fall_seconds: float = 0.5
## Seconds an ink splash stays visible where a blow lands.
@export var splash_seconds: float = 0.6

const SPLASH_RED := Color("8a2a20")
## Seconds the ring stays on a squad you've just ordered an attack on.
const FLASH_SECONDS := 0.9

## The player's selected squad (drawn with a vermilion ring), or null.
var selected: Squad = null
var _flash_squad: Squad = null
var _flash_at: float = -10.0

## How far between the last tick and the next we are (0 to 1). Set by main.
var alpha: float = 1.0

var battle: Battle
var _figures: Dictionary = {}  # Soldier -> SoldierFigure or RiggedFigure
var _draw_order: Array[Soldier] = []
var _time: float = 0.0


func _ready() -> void:
	# Rigged parts are drawn much smaller than their textures; mipmaps keep them clean.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


## Briefly ring a squad, to confirm it has just been ordered against.
func flash(squad: Squad) -> void:
	_flash_squad = squad
	_flash_at = _time


func show_battle(b: Battle) -> void:
	battle = b
	selected = null
	_flash_squad = null
	_figures.clear()
	for s in battle.soldiers:
		_figures[s] = _make_figure(s)
	_draw_order = battle.soldiers.duplicate()
	_draw_order.sort_custom(func(a: Soldier, c: Soldier) -> bool:
		return a.row > c.row if a.row != c.row else a.x < c.x)
	queue_redraw()


func _make_figure(s: Soldier) -> RefCounted:
	var side_def := battle.side_setup(s.side)
	var rig_path := s.squad.troop.rig_path
	if rig_path != "":
		var rigged := RiggedFigure.new(rig_path, s, side_def)
		if rigged.has_parts():
			return rigged
	return SoldierFigure.new(s, side_def)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	if battle == null:
		return
	if selected != null:
		_draw_ring(selected, Palette.VERMILION, 1.0)
	if _flash_squad != null and _time - _flash_at < FLASH_SECONDS:
		_draw_ring(_flash_squad, Palette.INK, 1.0 - (_time - _flash_at) / FLASH_SECONDS)
	for squad in battle.squads:
		if not squad.standing().is_empty():
			_draw_nobori(squad)
	# The fallen lie behind those still fighting. Those who fled are gone.
	for s in _draw_order:
		if s.state == Soldier.State.DOWN:
			_draw_soldier(s)
	for s in _draw_order:
		if s.is_standing():
			_draw_soldier(s)
	for s in _draw_order:
		_draw_wound(s)


func ground_y(x: float) -> float:
	return HillsideView.FIELD_HEIGHT - battle.terrain.height_at(x)


## An ink ring on the ground around a squad's standing soldiers.
func _draw_ring(squad: Squad, colour: Color, strength: float) -> void:
	var standing := squad.standing()
	if standing.is_empty():
		return
	var lo := INF
	var hi := -INF
	for s in standing:
		var x := lerpf(s.prev_x, s.x, alpha)
		lo = minf(lo, x)
		hi = maxf(hi, x)
	var mid := (lo + hi) * 0.5
	var centre := Vector2(mid, ground_y(mid) + 3.0)
	var radius := Vector2((hi - lo) * 0.5 + 22.0, 10.0)
	var pts := PackedVector2Array()
	for i in 41:
		var a := TAU * i / 40.0
		# A slightly uneven brush ring, thicker at the front.
		pts.append(centre + Vector2(cos(a) * radius.x, sin(a) * radius.y * (1.0 + 0.15 * sin(a * 3.0))))
	var c := colour
	c.a = strength
	draw_polyline(pts, c, 4.0, true)


## Seconds since a tick, using the drawing position between ticks.
func _since(tick: int) -> float:
	if tick < 0:
		return INF
	return (battle.tick_count + alpha - tick) * battle.dt


func _draw_soldier(s: Soldier) -> void:
	var depth := BACK_ROW_SCALE if s.row == 1 else 1.0
	var facing := Battle.facing(s.side)
	if s.state == Soldier.State.FLEEING:
		facing = -facing  # Running for home.
	var lift := BACK_ROW_LIFT if s.row == 1 else 0.0
	var x := lerpf(s.prev_x, s.x, alpha)
	var walking := s.is_standing() and s.x != s.prev_x
	var strike := clampf(_since(s.last_strike_tick) / strike_seconds, 0.0, 1.0)
	var flinch := clampf(_since(s.last_hit_tick) / flinch_seconds, 0.0, 1.0)
	var fall := clampf(_since(s.down_tick) / fall_seconds, 0.0, 1.0) if not s.is_standing() else 0.0
	var feet := Vector2(x, ground_y(x) - lift + 1.0)
	var rigged := _figures[s] as RiggedFigure
	if rigged != null:
		var rig_size := rigged.scale * depth * figure_size
		var rig_angle := sin(_time * rigged.sway_speed + rigged.sway_phase) * SWAY_ANGLE
		if walking:
			rig_angle += facing * march_lean * 0.5
		var pose: Dictionary
		if not s.is_standing():
			pose = RiggedFigure.blend(rigged.pose_at("recoil", 0.0), rigged.pose_at("down", 0.0), fall)
			rig_angle = 0.0
		elif strike < 1.0:
			pose = RiggedFigure.blend(rigged.pose_at("ready", 0.0), rigged.pose_at("thrust", 0.0), sin(strike * PI))
		elif flinch < 1.0:
			pose = RiggedFigure.blend(rigged.pose_at("recoil", 0.0), rigged.pose_at("ready", 0.0), flinch)
		elif walking:
			pose = rigged.pose_at(rigged_walk_animation, _time)
		elif s.state == Soldier.State.FIGHTING:
			pose = rigged.pose_at("ready", 0.0)
		else:
			pose = rigged.pose_at(rigged_rest_animation, _time)
		var rig_xf := Transform2D(rig_angle, Vector2(rig_size * facing, rig_size), 0.0, feet)
		rigged.draw(self, rig_xf, pose)
		return
	var fig: SoldierFigure = _figures[s]
	var size := fig.scale * depth * figure_size
	var angle := sin(_time * fig.sway_speed + fig.sway_phase) * SWAY_ANGLE
	var offset := Vector2.ZERO
	if not s.is_standing():
		# Topples backwards and lies where they fell.
		angle = -facing * PI * 0.5 * ease(fall, 0.4)
		offset.y = -2.0 * fall
	elif strike < 1.0:
		# Lunge forward with the blow.
		var k := sin(strike * PI)
		offset.x = facing * 6.0 * size * k
		angle = facing * 0.18 * k
	elif flinch < 1.0:
		var k := sin(flinch * PI)
		offset.x = -facing * 3.0 * size * k
		angle = -facing * 0.12 * k
	elif walking:
		# Each step lifts the body; steps are tied to distance walked.
		var phase := (x * facing + fig.sway_phase * stride_length) / stride_length * PI
		offset.y = -absf(sin(phase)) * stride_bob * size
		angle = facing * march_lean + sin(phase) * SWAY_ANGLE
	var xf := Transform2D(angle, Vector2(size * facing, size), 0.0, feet + offset)
	PaperDraw.draw_figure(self, fig.shapes, fig.details, xf, 0.9)


## A splash of ink where a blow lands, fading quickly.
func _draw_wound(s: Soldier) -> void:
	var t := _since(s.last_hit_tick)
	if t >= splash_seconds:
		return
	var x := lerpf(s.prev_x, s.x, alpha)
	var lift := BACK_ROW_LIFT if s.row == 1 else 0.0
	var centre := Vector2(x, ground_y(x) - lift - 28.0 * figure_size)
	var rng := RandomNumberGenerator.new()
	rng.seed = s.id * 7919 + s.last_hit_tick
	var fade := 1.0 - t / splash_seconds
	for i in 6:
		var off := Vector2(rng.randf_range(-7.0, 7.0), rng.randf_range(-8.0, 6.0)) * (0.6 + t * 2.0)
		var colour := SPLASH_RED if i % 3 else Palette.INK
		colour.a = 0.85 * fade
		draw_circle(centre + off, rng.randf_range(1.2, 3.2) * figure_size * 0.7, colour)


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
