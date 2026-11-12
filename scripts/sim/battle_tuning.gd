class_name BattleTuning
extends Resource
## Battle-wide numbers to tune by playtesting. Edit data/battle_tuning.tres.

## Simulation steps per second. The simulation runs at this fixed rate so a
## skirmish replays exactly from its seed.
@export_range(5, 60) var tick_rate: int = 20
## Seconds both armies stand still at the start before marching.
@export var march_delay: float = 1.5
## How much climbing slows a squad. At 1.0, a 1-in-3 slope cuts speed by a third.
@export var uphill_slowdown: float = 1.5
## How much going downhill speeds a squad up.
@export var downhill_speedup: float = 0.8
## Gap left between the front ranks when two squads meet, in field units.
@export var contact_gap: float = 16.0

@export_group("Fighting")
## A squad breaks into individual fights when an enemy comes this close.
@export var engage_distance: float = 45.0
## Closest two enemies can stand to each other, in field units.
@export var body_gap: float = 7.0
## Closest a soldier stands behind a comrade in the same row, so fights form
## ranks instead of a pile. Long spears can still strike past the rank ahead.
@export var rank_gap: float = 12.0
## Chance a blow lands between two equally skilled soldiers on level ground.
@export_range(0.0, 1.0) var base_hit_chance: float = 0.45
## How much a skill gap shifts the hit chance (skill runs 0 to 1).
@export var skill_effect: float = 0.6
## Hit chance bonus for striking from higher ground.
@export var height_bonus: float = 0.1
## Height difference, in field units, that earns the full height bonus.
@export var height_for_full_bonus: float = 25.0
## Hit chance bonus on a first blow struck while charging downhill.
@export var charge_bonus: float = 0.15
## Speed multiplier for anyone pushing through an enemy's spear zone (between
## the spear's close_range and its reach). Low means the spearmen get more
## thrusts in before the attacker reaches them.
@export_range(0.05, 1.0) var spear_zone_slowdown: float = 0.3

@export_group("Command bar")
## Orders the bar holds when full.
@export var command_bar_max: float = 3.0
## Seconds for the bar to refill by one order. Later this comes from the
## commander's communication skill.
@export var command_refill_seconds: float = 6.0
## What one order (attack or retreat) costs.
@export var order_cost: float = 1.0
## The bar starts this full.
@export var command_bar_start: float = 3.0
## Retreating soldiers run this much faster than they march.
@export var retreat_speed_factor: float = 1.4
## How far past the field's edge a retreating soldier runs before they're gone.
@export var leave_margin: float = 30.0
