class_name Soldier
extends RefCounted
## One person on the field. Their stats are hidden: rolled from their troop
## type's ranges with the battle's seed, and never shown to the player as numbers.

enum State { FORMED, FIGHTING, FLEEING, DOWN, GONE }

var id: int
var side: int  # 0 = left, 1 = right
var squad: Squad
var is_commander: bool = false
## Position along the battle line, in field units.
var x: float = 0.0
## Position at the previous tick, so the view can draw smoothly between ticks.
var prev_x: float = 0.0
## Depth row inside the squad: 0 = front, 1 = back. Purely for readability.
var row: int = 0
## Drives individual appearance (skin, sash, height), so everyone is recognisable.
var look_seed: int = 0

# --- Hidden stats -----------------------------------------------------------
## Weapon skill, 0 (hopeless) to 1 (master).
var skill: float = 0.5
## How much punishment they can take before falling.
var toughness: float = 80.0
## Personal speed, around 1.0.
var pace: float = 1.0

# --- Fight state -------------------------------------------------------------
var state: State = State.FORMED
var health: float = 80.0
var target: Soldier = null
## Ticks until this soldier can strike again.
var cooldown: int = 0
## Whether this soldier has struck yet (the first blow can be a charge).
var has_struck: bool = false
## Tick of the most recent strike, hit taken, and fall (-1 = never). The view
## uses these to time animations.
var last_strike_tick: int = -1
var last_hit_tick: int = -1
var down_tick: int = -1

# --- Observable record (the box score shown after a battle, later) ----------
var kills: int = 0
## Distance to whoever struck the fatal blow, for checking tactics in tests.
var fell_at_distance: float = -1.0


## Still on the field and on their feet (fighting, waiting or running away).
func is_standing() -> bool:
	return state == State.FORMED or state == State.FIGHTING or state == State.FLEEING


## Left the field by running off their home edge.
func is_gone() -> bool:
	return state == State.GONE
