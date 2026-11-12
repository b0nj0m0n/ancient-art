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
	_check_many_seeds(setup)
	print("FAILED: %d check(s)" % _failures if _failures else "All battle checks passed")
	quit(1 if _failures else 0)


func _expect(ok: bool, what: String) -> void:
	print(("  ok    " if ok else "  FAIL  ") + what)
	if not ok:
		_failures += 1


func _run(setup: SkirmishSetup, seed_override: int = -1) -> Battle:
	var b := Battle.new(setup, seed_override)
	while not b.is_over() and b.tick_count < MAX_TICKS:
		b.tick()
	return b


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
		var b := _run(setup, 1000 + seed)
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
	print("\n  Balance report over %d seeds:" % done)
	print("    %s win %d%%" % [setup.left.side_name, roundi(100.0 * wins[0] / maxi(done, 1))])
	print("    %s win %d%%" % [setup.right.side_name, roundi(100.0 * wins[1] / maxi(done, 1))])
	print("    average length %.0f s" % (seconds / maxi(done, 1)))
	for k in per:
		print("    kills per %s: %.2f" % [k, per[k]])
	print("")
