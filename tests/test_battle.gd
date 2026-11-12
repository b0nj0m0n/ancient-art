extends SceneTree
## Headless checks on the battle simulation, plus a balance report. Run with:
##   godot --headless --script tests/test_battle.gd
## Exits with code 1 if any check fails. CI runs this on every push.

const SETUP := "res://data/skirmish_setup.tres"
## Longest a skirmish may run before we call it stuck: 3 minutes at 20 ticks/s.
const MAX_TICKS := 3600
## Seeds in the balance report.
const SEEDS := 200

var _failures := 0


func _init() -> void:
	var setup: SkirmishSetup = load(SETUP)
	_check_replay_is_exact(setup)
	_check_enemies_never_pass(setup)
	_check_player_squads_hold(setup)
	_check_command_bar(setup)
	_check_retreat(setup)
	_check_orders_replay(setup)
	_check_many_seeds(setup)
	_balance_report(setup, "Player holds", false)
	_balance_report(setup, "Player charges the samurai at once", true)
	print("FAILED: %d check(s)" % _failures if _failures else "All battle checks passed")
	quit(1 if _failures else 0)


func _expect(ok: bool, what: String) -> void:
	print(("  ok    " if ok else "  FAIL  ") + what)
	if not ok:
		_failures += 1


func _run(setup: SkirmishSetup, seed_override: int = -1, charge := false) -> Battle:
	var b := Battle.new(setup, seed_override)
	if charge:
		_charge(b)
	while not b.is_over() and b.tick_count < MAX_TICKS:
		b.tick()
	return b


## Player orders their samurai to attack the enemy's first squad.
func _charge(b: Battle) -> void:
	var mine := _squad(b, b.setup.player_side, "Samurai")
	var theirs := _first_squad(b, 1 - b.setup.player_side)
	b.order_attack(mine, theirs)


func _squad(b: Battle, side: int, troop_name: String) -> Squad:
	for q in b.squads:
		if q.side == side and q.troop.display_name == troop_name:
			return q
	return null


func _first_squad(b: Battle, side: int) -> Squad:
	for q in b.squads:
		if q.side == side:
			return q
	return null


func _ticks(b: Battle, seconds: float) -> void:
	for i in roundi(seconds / b.dt):
		b.tick()


func _check_player_squads_hold(setup: SkirmishSetup) -> void:
	var b := Battle.new(setup)
	var start := {}
	for q in b.squads:
		start[q] = q.anchor_x
	_ticks(b, 4.0)
	var held := true
	var enemy_moved := false
	for q in b.squads:
		if b.is_player_side(q.side):
			held = held and q.anchor_x == start[q]
		elif q.anchor_x != start[q]:
			enemy_moved = true
	_expect(held, "the player's squads hold until ordered")
	_expect(enemy_moved, "the computer's squads march on their own")


func _check_command_bar(setup: SkirmishSetup) -> void:
	var b := Battle.new(setup)
	var side := setup.player_side
	var mine := _squad(b, side, "Samurai")
	var theirs := _first_squad(b, 1 - side)
	var given := 0
	for i in 4:
		if b.order_attack(mine, theirs):
			given += 1
	_expect(given == 3, "a full bar holds three orders (gave %d of 4)" % given)
	_ticks(b, setup.tuning.command_refill_seconds + 0.2)
	_expect(b.order_attack(mine, theirs), "the bar refills one order in %.0f s" % setup.tuning.command_refill_seconds)


func _check_retreat(setup: SkirmishSetup) -> void:
	var b := Battle.new(setup)
	var archers := _squad(b, setup.player_side, "Archers")
	_ticks(b, 2.0)
	b.order_retreat(archers)
	_ticks(b, 25.0)
	var gone := 0
	for s in archers.soldiers:
		if s.is_gone():
			gone += 1
	_expect(gone == archers.soldiers.size(), "retreating archers run off their home edge (%d of %d gone)" % [gone, archers.soldiers.size()])


func _check_orders_replay(setup: SkirmishSetup) -> void:
	var a := Battle.new(setup)
	var side := setup.player_side
	_ticks(a, 2.0)
	_charge(a)
	_ticks(a, 3.0)
	a.order_retreat(_squad(a, side, "Archers"))
	while not a.is_over() and a.tick_count < MAX_TICKS:
		a.tick()
	var b := Battle.new(setup, -1, a.order_log)
	while not b.is_over() and b.tick_count < MAX_TICKS:
		b.tick()
	var same := a.tick_count == b.tick_count and a.winner == b.winner and a.order_log.size() == 2
	for i in a.soldiers.size():
		same = same and a.soldiers[i].x == b.soldiers[i].x and a.soldiers[i].state == b.soldiers[i].state
	_expect(same, "a battle with orders replays exactly from its order log")


func _check_replay_is_exact(setup: SkirmishSetup) -> void:
	var a := _run(setup)
	var b := _run(setup)
	var same := a.tick_count == b.tick_count and a.winner == b.winner
	for i in a.soldiers.size():
		var p := a.soldiers[i]
		var q := b.soldiers[i]
		same = same and p.x == q.x and p.health == q.health and p.state == q.state and p.kills == q.kills
	_expect(same, "same seed gives an identical skirmish")
	_expect(a.is_over(), "the skirmish ends with a winner (after %.0f s)" % a.elapsed())


func _check_enemies_never_pass(setup: SkirmishSetup) -> void:
	# Every standing left soldier stays left of every standing right soldier, every tick.
	var b := Battle.new(setup)
	var ok := true
	while not b.is_over() and b.tick_count < MAX_TICKS and ok:
		b.tick()
		var max_left := -INF
		var min_right := INF
		for s in b.soldiers:
			if not s.is_standing():
				continue
			if s.side == Battle.LEFT:
				max_left = maxf(max_left, s.x)
			else:
				min_right = minf(min_right, s.x)
		ok = max_left < min_right
	_expect(ok, "standing enemies never walk through each other")


func _check_many_seeds(setup: SkirmishSetup) -> void:
	var wins := [0, 0]
	var stuck := 0
	var seconds := 0.0
	var kills_by_troop := {}
	var count_by_troop := {}
	var spear: TroopType = null
	var died_at_spearpoint := 0
	var spearmen_killed_inside := 0
	for seed in SEEDS:
		var b := _run(setup, 1000 + seed, true)
		if not b.is_over():
			stuck += 1
			continue
		wins[b.winner] += 1
		seconds += b.elapsed()
		for s in b.soldiers:
			var t := s.squad.troop
			kills_by_troop[t.display_name] = kills_by_troop.get(t.display_name, 0) + s.kills
			count_by_troop[t.display_name] = count_by_troop.get(t.display_name, 0) + 1
			if t.close_range > 0.0:
				spear = t
		# The spear rule: who fell in the spear zone, and spearmen caught up close.
		for s in b.soldiers:
			if s.state != Soldier.State.DOWN or spear == null:
				continue
			if s.squad.troop == spear:
				if s.fell_at_distance < spear.close_range:
					spearmen_killed_inside += 1
			elif s.fell_at_distance >= spear.close_range and s.fell_at_distance <= spear.reach:
				died_at_spearpoint += 1
	var done := SEEDS - stuck
	_expect(stuck == 0, "every skirmish ends within %d s (%d stuck)" % [MAX_TICKS / 20, stuck])
	_expect(died_at_spearpoint > 0, "attackers fall at spearpoint (%d across %d battles)" % [died_at_spearpoint, done])
	_expect(spearmen_killed_inside > 0, "survivors get inside and cut spearmen down (%d)" % spearmen_killed_inside)
	var per := {}
	for k in kills_by_troop:
		per[k] = float(kills_by_troop[k]) / count_by_troop[k]
	_expect(per.get("Samurai", 0.0) > per.get("Ashigaru spearmen", 0.0),
		"samurai are the best fighters, man for man")


func _balance_report(setup: SkirmishSetup, label: String, charge: bool) -> void:
	var wins := [0, 0]
	var seconds := 0.0
	var done := 0
	for seed in SEEDS:
		var b := _run(setup, 1000 + seed, charge)
		if not b.is_over():
			continue
		done += 1
		wins[b.winner] += 1
		seconds += b.elapsed()
	print("\n  Balance, %s (%d seeds):" % [label, done])
	print("    %s win %d%%" % [setup.left.side_name, roundi(100.0 * wins[0] / maxi(done, 1))])
	print("    %s win %d%%" % [setup.right.side_name, roundi(100.0 * wins[1] / maxi(done, 1))])
	print("    average length %.0f s" % (seconds / maxi(done, 1)))
