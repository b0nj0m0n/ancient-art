class_name Battle
extends RefCounted
## The skirmish simulation. For now it only lines both armies up.
## All randomness comes from one seeded generator so a skirmish can be replayed exactly.

const LEFT := 0
const RIGHT := 1
## Spacing between soldiers in a row, in field units.
const SOLDIER_SPACING := 24.0

var setup: SkirmishSetup
var terrain: Terrain
var rng := RandomNumberGenerator.new()
var squads: Array[Squad] = []
var soldiers: Array[Soldier] = []


func _init(skirmish: SkirmishSetup) -> void:
	setup = skirmish
	terrain = skirmish.terrain
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
			s.look_seed = rng.randi()
			s.is_commander = def.has_commander and k == commander_slot
			squad.soldiers.append(s)
			soldiers.append(s)
		squads.append(squad)
