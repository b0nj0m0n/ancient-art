class_name Terrain
extends Resource
## The battlefield's shape along the single left-to-right line.
## Heights are in field units above the bottom of the field.
## Tunable in data/hillside.tres.

## Width of the playable field, left edge to right edge.
@export var field_width: float = 1280.0
## Ground height at the lowest point.
@export var base_height: float = 150.0
## How high the hill rises above the base.
@export var hill_height: float = 150.0
## Where the hill's top sits, as a fraction of the field width (0 = left, 1 = right).
@export_range(0.0, 1.0) var hill_peak: float = 0.78
## How spread out the hill is, as a fraction of the field width.
@export_range(0.05, 1.0) var hill_spread: float = 0.32


## Ground height at field position x. Positions outside the field are clamped.
func height_at(x: float) -> float:
	var t: float = clampf(x / field_width, 0.0, 1.0)
	var d: float = (t - hill_peak) / hill_spread
	return base_height + hill_height * exp(-d * d)


## Rise per unit of x. Positive means the ground climbs toward the right.
func slope_at(x: float) -> float:
	return (height_at(x + 1.0) - height_at(x - 1.0)) * 0.5
