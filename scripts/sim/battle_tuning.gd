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
