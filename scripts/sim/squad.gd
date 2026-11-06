class_name Squad
extends RefCounted
## A group of soldiers that takes orders together.

var side: int
var index: int
var troop: TroopType
var soldiers: Array[Soldier] = []
var has_commander: bool = false
## Where the squad's banner stands, in field units.
var anchor_x: float = 0.0
