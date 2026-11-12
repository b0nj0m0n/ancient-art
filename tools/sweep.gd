extends SceneTree
## Balance sweep: tries combinations of a few key numbers (in memory only, the
## data files are not changed) and prints win rates, so tuning is informed.
##   godot --headless --script tools/sweep.gd

const SEEDS := 120

func _init() -> void:
	var setup: SkirmishSetup = load("res://data/skirmish_setup.tres")
	var ash: TroopType = load("res://data/troops/ashigaru.tres")
	var sam: TroopType = load("res://data/troops/samurai.tres")
	print("spear_dmg slowdown sam_armour | left_win%  len  sam_died_at_spearpoint%")
	for dmg in [40.0, 48.0, 55.0]:
		for slow in [0.2, 0.3, 0.45]:
			for arm in [0.35, 0.45]:
				ash.damage = dmg
				setup.tuning.spear_zone_slowdown = slow
				sam.armour = arm
				var left := 0
				var secs := 0.0
				var sam_spear := 0
				var sam_total := 0
				for seed in SEEDS:
					var b := Battle.new(setup, 5000 + seed)
					while not b.is_over() and b.tick_count < 3600:
						b.tick()
					if b.winner == Battle.LEFT:
						left += 1
					secs += b.elapsed()
					for s in b.soldiers:
						if s.squad.troop == sam:
							sam_total += 1
							if s.state == Soldier.State.DOWN and s.fell_at_distance >= ash.close_range:
								sam_spear += 1
				print("%6.0f %8.2f %8.2f    | %5d%% %6.0fs %8d%%" % [dmg, slow, arm,
					roundi(100.0 * left / SEEDS), secs / SEEDS, roundi(100.0 * sam_spear / sam_total)])
	quit()
