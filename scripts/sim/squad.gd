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
var prev_anchor_x: float = 0.0
## True while the squad is marching as a block this tick.
var moving: bool = false
## Once an enemy comes close, the squad breaks into individual fights.
var engaged: bool = false

enum Order { HOLD, ADVANCE, ATTACK, RETREAT }
## What the squad is doing. Player squads start on HOLD; squads run by the
## computer start on ADVANCE (or HOLD if their troop holds position).
var order: Order = Order.HOLD
## The enemy squad an ATTACK order is aimed at.
var target_squad: Squad = null


func standing() -> Array[Soldier]:
	var out: Array[Soldier] = []
	for s in soldiers:
		if s.is_standing():
			out.append(s)
	return out
