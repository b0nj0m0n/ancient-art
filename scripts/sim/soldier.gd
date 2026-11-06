class_name Soldier
extends RefCounted
## One person on the field. Hidden stats will live here; they are never shown as numbers.

var id: int
var side: int  # 0 = left, 1 = right
var squad: Squad
var is_commander: bool = false
## Position along the battle line, in field units.
var x: float = 0.0
## Depth row inside the squad: 0 = front, 1 = back. Purely for readability.
var row: int = 0
## Drives individual appearance (skin, sash, height), so everyone is recognisable.
var look_seed: int = 0
