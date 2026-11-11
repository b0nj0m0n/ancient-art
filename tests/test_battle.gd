extends SceneTree
## Headless checks on the battle simulation. Run with:
##   godot --headless --script tests/test_battle.gd
## Exits with code 1 if any check fails. CI runs this on every push.

const SETUP := "res://data/skirmish_setup.tres"
const TICKS := 1200  # 60 seconds at 20 ticks per second

var _failures := 0


func _init() -> void:
	var setup: SkirmishSetup = load(SETUP)
	_check_replay_is_exact(setup)
	_check_armies_advance_and_meet(setup)
	print("FAILED: %d check(s)" % _failures if _failures else "All battle checks passed")
	quit(1 if _failures else 0)


func _expect(ok: bool, what: String) -> void:
	print(("  ok    " if ok else "  FAIL  ") + what)
	if not ok:
		_failures += 1


func _run(setup: SkirmishSetup, ticks: int) -> Battle:
	var b := Battle.new(setup)
	for i in ticks:
		b.tick()
	return b


func _check_replay_is_exact(setup: SkirmishSetup) -> void:
	var a := _run(setup, TICKS)
	var b := _run(setup, TICKS)
	var same := a.soldiers.size() == b.soldiers.size()
	for i in a.soldiers.size():
		same = same and a.soldiers[i].x == b.soldiers[i].x and a.soldiers[i].look_seed == b.soldiers[i].look_seed
	_expect(same, "same seed gives an identical skirmish")


func _check_armies_advance_and_meet(setup: SkirmishSetup) -> void:
	var start := Battle.new(setup)
	var end := _run(setup, TICKS)
	var left_start := start.front_x(start.squads[0])
	var left_end := end.front_x(end.squads[0])
	_expect(left_end > left_start + 100.0, "left army marches forward (%.0f -> %.0f)" % [left_start, left_end])
	# No soldier may pass through an enemy: every left soldier stays left of every right soldier.
	var max_left := -INF
	var min_right := INF
	for s in end.soldiers:
		if s.side == Battle.LEFT:
			max_left = maxf(max_left, s.x)
		else:
			min_right = minf(min_right, s.x)
	_expect(max_left < min_right, "the armies never pass through each other")
	var gap := min_right - max_left
	_expect(gap <= end.tuning.contact_gap + 1.0, "the front ranks meet and halt (gap %.1f)" % gap)
	var moving := 0
	for sq in end.squads:
		if sq.moving:
			moving += 1
	_expect(moving == 0, "everyone has halted by the end")
	for sq in end.squads:
		if sq.troop.holds_position:
			_expect(is_equal_approx(sq.anchor_x, start.squads[end.squads.find(sq)].anchor_x), "%s hold their position" % sq.troop.display_name)
