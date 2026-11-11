class_name Battle
extends RefCounted
## The skirmish simulation. It runs in fixed ticks (see BattleTuning.tick_rate)
## and knows nothing about drawing, so the art can change without touching it.
## All randomness comes from one seeded generator so a skirmish can be replayed exactly.

const LEFT := 0
const RIGHT := 1
## Spacing between soldiers in a row, in field units.
const SOLDIER_SPACING := 24.0

var setup: SkirmishSetup
var terrain: Terrain
var tuning: BattleTuning
## Seconds per tick.
var dt: float
var tick_count: int = 0
var rng := RandomNumberGenerator.new()
var squads: Array[Squad] = []
var soldiers: Array[Soldier] = []


func _init(skirmish: SkirmishSetup) -> void:
	setup = skirmish
	terrain = skirmish.terrain
	tuning = skirmish.tuning
	dt = 1.0 / tuning.tick_rate
	rng.seed = skirmish.rng_seed
	_build_side(skirmish.left, LEFT)
	_build_side(skirmish.right, RIGHT)


func side_setup(side: int) -> SideSetup:
	return setup.left if side == LEFT else setup.right


func _build_side(side_def: SideSetup, side: int) -> void:
	for i in side_def.squads.size():
		var def := side_def.squads[i]
		var squad := Squad.new()
		squad.side = side
		squad.index = i
		squad.troop = def.troop
		squad.has_commander = def.has_commander
		squad.anchor_x = def.start_position * terrain.field_width
		squad.prev_anchor_x = squad.anchor_x
		var rows := 2 if def.size > 3 else 1
		var cols := ceili(def.size / float(rows))
		var commander_slot := floori(cols / 2.0) * rows  # front row, middle column
		for k in def.size:
			var s := Soldier.new()
			s.id = soldiers.size()
			s.side = side
			s.squad = squad
			s.row = k % rows
			var col := floori(k / float(rows))
			s.x = squad.anchor_x + (col - (cols - 1) * 0.5) * SOLDIER_SPACING \
				+ s.row * SOLDIER_SPACING * 0.5 + rng.randf_range(-2.0, 2.0)
			s.prev_x = s.x
			s.look_seed = rng.randi()
			s.is_commander = def.has_commander and k == commander_slot
			squad.soldiers.append(s)
			soldiers.append(s)
		squads.append(squad)


## Advance the simulation by one tick.
func tick() -> void:
	tick_count += 1
	for s in soldiers:
		s.prev_x = s.x
	for squad in squads:
		squad.prev_anchor_x = squad.anchor_x
		squad.moving = false
	if tick_count * dt < tuning.march_delay:
		return
	for squad in squads:
		_advance(squad)


## March a squad toward the enemy until its front rank meets theirs.
func _advance(squad: Squad) -> void:
	if squad.troop.holds_position or squad.soldiers.is_empty():
		return
	var dir := facing(squad.side)
	var front := front_x(squad)
	var step := squad.troop.march_speed * slope_factor(squad.anchor_x, dir) * dt
	var enemy := _nearest_enemy_ahead(squad.side, front, dir)
	if is_finite(enemy):
		var room := absf(enemy - front) - tuning.contact_gap
		step = minf(step, maxf(room, 0.0))
	if step <= 0.0:
		return
	squad.moving = true
	squad.anchor_x += dir * step
	for s in squad.soldiers:
		s.x += dir * step


## +1 for the left side (marches right), -1 for the right side.
static func facing(side: int) -> float:
	return 1.0 if side == LEFT else -1.0


## Speed multiplier from the slope underfoot: slower climbing, faster descending.
func slope_factor(x: float, dir: float) -> float:
	var climb := terrain.slope_at(x) * dir
	var f := 1.0 - tuning.uphill_slowdown * maxf(climb, 0.0) + tuning.downhill_speedup * maxf(-climb, 0.0)
	return clampf(f, 0.3, 1.6)


## The squad's leading edge: its soldier furthest toward the enemy.
func front_x(squad: Squad) -> float:
	var dir := facing(squad.side)
	var best := -INF
	for s in squad.soldiers:
		best = maxf(best, s.x * dir)
	return best * dir


func _nearest_enemy_ahead(side: int, from_x: float, dir: float) -> float:
	var best := INF
	for s in soldiers:
		if s.side == side:
			continue
		var ahead := (s.x - from_x) * dir
		if ahead >= 0.0 and ahead < absf(best - from_x):
			best = s.x
	return best

