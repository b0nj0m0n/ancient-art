class_name SkirmishSetup
extends Resource
## Everything needed to start one skirmish. Same seed gives the same skirmish.

@export var rng_seed: int = 1560
@export var terrain: Terrain
@export var tuning: BattleTuning
@export var left: SideSetup
@export var right: SideSetup

@export_group("Trees")
## Field range (fractions of the width) where trees grow.
@export var tree_area: Vector2 = Vector2(0.0, 0.24)
@export_range(0, 20) var tree_count: int = 7

@export_group("Town")
## Field range (fractions of the width) where the town's buildings stand.
@export var town_area: Vector2 = Vector2(0.84, 1.0)
@export_range(0, 10) var building_count: int = 4
