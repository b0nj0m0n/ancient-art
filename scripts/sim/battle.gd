class_name Battle
extends RefCounted
## The skirmish simulation. It runs in fixed ticks (see BattleTuning.tick_rate)
## and knows nothing about drawing, so the art can change without touching it.
## All randomness comes from one seeded generator so a skirmish can be replayed exactly.
##
## How a fight unfolds:
## 1. Squads march as blocks until an enemy comes within engage_distance.
## 2. Then every soldier fights on their own: picks the nearest standing enemy,
##    moves to their troop's preferred range, and strikes whenever their weapon
##    reaches and they're ready.
## 3. Reach matters. Spearmen brace at spear's length and strike anyone crossing
##    it. Pushing through spear points is slow (spear_zone_slowdown), so the
##    attacker takes several thrusts; whoever dies there falls where they stand.
##    Whoever survives closes in, where the long spear is clumsy
##    (close_range / close_effectiveness).
## 4. The battle ends when one side has no one left on the field (fallen or fled).
##
## Orders: the player's squads hold until ordered. Each order (attack a squad,
## or retreat) spends the side's command bar, which refills over time. Orders
## take effect on the next tick and are logged with that tick, so a battle
## replays exactly from its seed plus its order log.

const LEFT := 0
const RIGHT := 1
const NO_WINNER := -1
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
## The side holding the field at the end, or NO_WINNER while the fight goes on.
var winner: int = NO_WINNER
## Command bar per side, measured in orders (see BattleTuning).
var command: Array[float] = [0.0, 0.0]
## Every order applied, as {tick, side, squad, kind, target}. Feed it back to
## replay a battle exactly.
var order_log: Array[Dictionary] = []
var _pending: Array[Dictionary] = []
var _replay: Array[Dictionary] = []


## seed_override replays the same setup with a different seed (used by tests
## and balance reports); -1 uses the setup's own seed. replay is an order_log
## from an earlier battle: its orders are applied at the same ticks.
func _init(skirmish: SkirmishSetup, seed_override: int = -1, replay: Array[Dictionary] = []) -> void:
	setup = skirmish
	terrain = skirmish.terrain
	tuning = skirmish.tuning
	dt = 1.0 / tuning.tick_rate
	rng.seed = skirmish.rng_seed if seed_override < 0 else seed_override
	command = [tuning.command_bar_start, tuning.command_bar_start]
	_replay = replay.duplicate()
	_build_side(skirmish.left, LEFT)
	_build_side(skirmish.right, RIGHT)


func side_setup(side: int) -> SideSetup:
	return setup.left if side == LEFT else setup.right


func is_over() -> bool:
	return winner != NO_WINNER


func is_player_side(side: int) -> bool:
	return side == setup.player_side


# --- Orders --------------------------------------------------------------------

## True if the side's command bar holds enough for one order.
func can_order(side: int) -> bool:
	return command[side] >= tuning.order_cost


## Order a squad to attack an enemy squad. Returns false (and spends nothing)
## if the order can't be given.
func order_attack(squad: Squad, target: Squad) -> bool:
	if target == null or target.side == squad.side or target.standing().is_empty():
		return false
	return _queue(squad, Squad.Order.ATTACK, target)


## Order a squad to retreat off its home edge.
func order_retreat(squad: Squad) -> bool:
	return _queue(squad, Squad.Order.RETREAT, null)


func _queue(squad: Squad, kind: Squad.Order, target: Squad) -> bool:
	if is_over() or not can_order(squad.side) or squad.standing().is_empty():
		return false
	if squad.order == Squad.Order.RETREAT:
		return false  # Once running, they don't come back.
	command[squad.side] -= tuning.order_cost
	_pending.append({"side": squad.side, "squad": squads.find(squad), "kind": kind,
		"target": squads.find(target) if target != null else -1})
	return true


func _apply_orders() -> void:
	var due: Array[Dictionary] = []
	for o in _pending:
		var entry := o.duplicate()
		entry["tick"] = tick_count
		due.append(entry)
	_pending.clear()
	while not _replay.is_empty() and _replay[0]["tick"] == tick_count:
		var o: Dictionary = _replay.pop_front()
		command[o["side"]] -= tuning.order_cost
		due.append(o)
	for o in due:
		order_log.append(o)
		var squad := squads[o["squad"]]
		squad.order = o["kind"]
		squad.target_squad = squads[o["target"]] if o["target"] >= 0 else null
		if squad.order == Squad.Order.RETREAT:
			for s in squad.soldiers:
				if s.is_standing():
					s.state = Soldier.State.FLEEING
					s.target = null


## Seconds since the battle began.
func elapsed() -> float:
	return tick_count * dt


func _build_side(side_def: SideSetup, side: int) -> void:
	for i in side_def.squads.size():
		var def := side_def.squads[i]
		var squad := Squad.new()
		squad.side = side
		squad.index = i
		squad.troop = def.troop
		squad.has_commander = def.has_commander
		if side != setup.player_side and not def.troop.holds_position:
			squad.order = Squad.Order.ADVANCE
		squad.anchor_x = def.start_position * terrain.field_width
		squad.prev_anchor_x = squad.anchor_x
		var rows := 2 if def.size > 3 else 1
		var cols := ceili(def.size / float(rows))
		var commander_slot := floori(cols / 2.0) * rows  # front row, middle column
		var t := def.troop
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
			s.skill = rng.randf_range(t.skill_range.x, t.skill_range.y)
			s.toughness = rng.randf_range(t.toughness_range.x, t.toughness_range.y)
			s.pace = rng.randf_range(t.pace_range.x, t.pace_range.y)
			s.health = s.toughness
			squad.soldiers.append(s)
			soldiers.append(s)
		squads.append(squad)


## Advance the simulation by one tick.
func tick() -> void:
	if is_over():
		return
	tick_count += 1
	for s in soldiers:
		s.prev_x = s.x
	for squad in squads:
		squad.prev_anchor_x = squad.anchor_x
		squad.moving = false
	_apply_orders()
	for side in 2:
		command[side] = minf(command[side] + dt / tuning.command_refill_seconds, tuning.command_bar_max)
	if elapsed() < tuning.march_delay:
		return
	for squad in squads:
		if squad.order == Squad.Order.RETREAT:
			continue
		if not squad.engaged:
			_check_engage(squad)
		if not squad.engaged:
			_march(squad)
	for s in soldiers:
		if s.state == Soldier.State.FLEEING:
			_flee(s)
		elif s.is_standing() and s.squad.engaged:
			_fight(s)
	for squad in squads:
		if squad.engaged or squad.order == Squad.Order.RETREAT:
			_follow_banner(squad)
	_check_winner()


# --- Marching ----------------------------------------------------------------

func _check_engage(squad: Squad) -> void:
	var standing := squad.standing()
	if standing.is_empty():
		return
	var front := front_x(squad)
	var enemy := _nearest_enemy_ahead(squad.side, front, facing(squad.side))
	if is_finite(enemy) and absf(enemy - front) <= tuning.engage_distance:
		squad.engaged = true
		for s in standing:
			s.state = Soldier.State.FIGHTING


## March a squad as one block: toward its target on ATTACK, toward the enemy
## side on ADVANCE. Squads on HOLD stay put.
func _march(squad: Squad) -> void:
	if squad.standing().is_empty():
		return
	if squad.order != Squad.Order.ADVANCE and squad.order != Squad.Order.ATTACK:
		return
	var dir := facing(squad.side)
	if squad.order == Squad.Order.ATTACK and squad.target_squad != null \
			and not squad.target_squad.standing().is_empty():
		dir = signf(squad.target_squad.anchor_x - squad.anchor_x)
		if dir == 0.0:
			dir = facing(squad.side)
	var front := front_x(squad)
	var step := squad.troop.march_speed * slope_factor(squad.anchor_x, dir) * dt
	var enemy := _nearest_enemy_ahead(squad.side, front, dir)
	if is_finite(enemy):
		step = minf(step, maxf(absf(enemy - front) - tuning.body_gap, 0.0))
	if step <= 0.0:
		return
	squad.moving = true
	squad.anchor_x += dir * step
	for s in squad.soldiers:
		if s.is_standing():
			s.x += dir * step


# --- Fighting ----------------------------------------------------------------

func _fight(s: Soldier) -> void:
	var t := s.squad.troop
	var aim := s.squad.target_squad if s.squad.order == Squad.Order.ATTACK else null
	if aim != null and aim.standing().is_empty():
		aim = null
	if s.target == null or not s.target.is_standing() or (aim != null and s.target.squad != aim):
		s.target = _nearest_enemy(s, aim)
	if s.target == null:
		return
	var dir := signf(s.target.x - s.x)
	var dist := absf(s.target.x - s.x)
	# Close to the preferred range, never nearer than body_gap to the nearest enemy ahead.
	if dist > t.preferred_range:
		var step := t.march_speed * s.pace * slope_factor(s.x, dir) * dt
		step = minf(step, dist - t.preferred_range)
		if _in_spear_zone(s, dir):
			step *= tuning.spear_zone_slowdown
		var blocker := _nearest_enemy_ahead(s.side, s.x, dir)
		if is_finite(blocker):
			step = minf(step, maxf(absf(blocker - s.x) - tuning.body_gap, 0.0))
		var comrade := _nearest_comrade_ahead(s, dir)
		if is_finite(comrade):
			step = minf(step, maxf(absf(comrade - s.x) - tuning.rank_gap, 0.0))
		s.x += dir * maxf(step, 0.0)
		dist = absf(s.target.x - s.x)
	if s.cooldown > 0:
		s.cooldown -= 1
		return
	if dist <= t.reach:
		_strike(s, s.target, dist)


func _strike(attacker: Soldier, defender: Soldier, dist: float) -> void:
	var t := attacker.squad.troop
	attacker.last_strike_tick = tick_count
	attacker.cooldown = maxi(1, roundi(t.attack_interval / dt * rng.randf_range(0.85, 1.15)))
	var p := tuning.base_hit_chance + tuning.skill_effect * (attacker.skill - defender.skill)
	var rise := terrain.height_at(attacker.x) - terrain.height_at(defender.x)
	p += tuning.height_bonus * clampf(rise / tuning.height_for_full_bonus, -1.0, 1.0)
	if not attacker.has_struck and _descending(attacker):
		p += tuning.charge_bonus
	attacker.has_struck = true
	if dist < t.close_range:
		p *= t.close_effectiveness
	if rng.randf() >= clampf(p, 0.03, 0.97):
		return
	var dmg := t.damage * rng.randf_range(0.7, 1.3) * (1.0 - defender.squad.troop.armour)
	defender.health -= dmg
	defender.last_hit_tick = tick_count
	if defender.health <= 0.0:
		defender.state = Soldier.State.DOWN
		defender.down_tick = tick_count
		defender.target = null
		defender.fell_at_distance = dist
		attacker.kills += 1


## True if s is pushing through the reach of a standing enemy spearman ahead.
func _in_spear_zone(s: Soldier, dir: float) -> bool:
	for e in soldiers:
		if e.side == s.side or not e.is_standing():
			continue
		var et := e.squad.troop
		if et.close_range <= 0.0:
			continue
		var d := (e.x - s.x) * dir
		if d > et.close_range and d <= et.reach:
			return true
	return false


func _descending(s: Soldier) -> bool:
	var moved := s.x - s.prev_x
	return moved != 0.0 and terrain.slope_at(s.x) * signf(moved) < 0.0


## Run for the home edge; once off the field, gone for this skirmish.
func _flee(s: Soldier) -> void:
	var home := -facing(s.side)
	var t := s.squad.troop
	s.x += home * t.march_speed * s.pace * tuning.retreat_speed_factor * slope_factor(s.x, home) * dt
	if s.x < -tuning.leave_margin or s.x > terrain.field_width + tuning.leave_margin:
		s.state = Soldier.State.GONE


## Once fighting breaks the block apart, the banner stays with the survivors.
func _follow_banner(squad: Squad) -> void:
	var standing := squad.standing()
	if standing.is_empty():
		return
	var sum := 0.0
	for s in standing:
		sum += s.x
	squad.anchor_x = sum / standing.size()


func _check_winner() -> void:
	var left := 0
	var right := 0
	for s in soldiers:
		if s.is_standing():
			if s.side == LEFT:
				left += 1
			else:
				right += 1
	if left == 0 and right > 0:
		winner = RIGHT
	elif right == 0 and left > 0:
		winner = LEFT


# --- Geometry helpers --------------------------------------------------------

## +1 for the left side (marches right), -1 for the right side.
static func facing(side: int) -> float:
	return 1.0 if side == LEFT else -1.0


## Speed multiplier from the slope underfoot: slower climbing, faster descending.
func slope_factor(x: float, dir: float) -> float:
	var climb := terrain.slope_at(x) * dir
	var f := 1.0 - tuning.uphill_slowdown * maxf(climb, 0.0) + tuning.downhill_speedup * maxf(-climb, 0.0)
	return clampf(f, 0.3, 1.6)


## The squad's leading edge: its standing soldier furthest toward the enemy.
func front_x(squad: Squad) -> float:
	var dir := facing(squad.side)
	var best := -INF
	for s in squad.soldiers:
		if s.is_standing():
			best = maxf(best, s.x * dir)
	return best * dir


func _nearest_enemy_ahead(side: int, from_x: float, dir: float) -> float:
	var best := INF
	for s in soldiers:
		if s.side == side or not s.is_standing():
			continue
		var ahead := (s.x - from_x) * dir
		if ahead >= 0.0 and ahead < absf(best - from_x):
			best = s.x
	return best


## The nearest standing soldier of the same side and row in front of me.
func _nearest_comrade_ahead(me: Soldier, dir: float) -> float:
	var best := INF
	for s in soldiers:
		if s == me or s.side != me.side or s.row != me.row or not s.is_standing():
			continue
		var ahead := (s.x - me.x) * dir
		if ahead > 0.0 and ahead < absf(best - me.x):
			best = s.x
	return best


## The nearest standing enemy, from within one squad if only_squad is given.
func _nearest_enemy(me: Soldier, only_squad: Squad = null) -> Soldier:
	var best: Soldier = null
	var best_d := INF
	for s in soldiers:
		if s.side == me.side or not s.is_standing():
			continue
		if only_squad != null and s.squad != only_squad:
			continue
		var d := absf(s.x - me.x)
		if d < best_d:
			best_d = d
			best = s
	return best
