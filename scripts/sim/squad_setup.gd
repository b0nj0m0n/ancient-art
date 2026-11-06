class_name SquadSetup
extends Resource
## One squad in a skirmish setup.

@export var troop: TroopType
@export_range(1, 10) var size: int = 5
## Default position across the field (0 = left edge, 1 = right edge).
## Should sit inside the side's home third.
@export_range(0.0, 1.0) var start_position: float = 0.2
## The side's commander marches with this squad.
@export var has_commander: bool = false
