class_name SceneryView
extends Node2D
## Draws the trees and the town as cut-paper set pieces standing just behind
## the battle line. Positions and shapes come from the skirmish seed.

const PINE_GREEN := Color("3f5a3c")
const CEDAR_GREEN := Color("4d6646")
const BARK := Color("4a3a30")
const WALL := Color("f2ede0")
const TIMBER := Color("3a2f28")
const THATCH := Color("8a7350")
const TILE := Color("5d5a58")
## How far up the page the scenery stands, to sit behind the soldiers.
const BACK_LIFT := 18.0

## Size of trees and buildings, to match the figures.
@export var piece_size: float = 1.35

var _pieces: Array = []  # [shapes, details, base point]
var _terrain: Terrain


func build(setup: SkirmishSetup) -> void:
	_terrain = setup.terrain
	_pieces.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = setup.rng_seed + 7919
	var w := _terrain.field_width
	var tree_xs := _spread(rng, setup.tree_area * w, setup.tree_count)
	var house_xs := _spread(rng, setup.town_area * w, setup.building_count)
	for i in house_xs.size():
		_pieces.append(_building(rng, house_xs[i], i % 3 == 1))
	for x in tree_xs:
		_pieces.append(_cedar(rng, x) if rng.randf() < 0.35 else _pine(rng, x))
	queue_redraw()


func _draw() -> void:
	for piece in _pieces:
		var base: Vector2 = piece[2]
		var xf := Transform2D(0.0, Vector2(piece_size, piece_size), 0.0, base) * Transform2D(0.0, -base)
		PaperDraw.draw_figure(self, piece[0], piece[1], xf, 2.0)


func _ground(x: float) -> Vector2:
	return Vector2(x, HillsideView.FIELD_HEIGHT - _terrain.height_at(x) - BACK_LIFT)


## Evenly spread positions across a range, with a little jitter.
func _spread(rng: RandomNumberGenerator, area: Vector2, count: int) -> Array[float]:
	var xs: Array[float] = []
	if count <= 0:
		return xs
	var step := (area.y - area.x) / count
	for i in count:
		xs.append(area.x + step * (i + 0.5) + rng.randf_range(-0.3, 0.3) * step)
	return xs


func _pine(rng: RandomNumberGenerator, x: float) -> Array:
	# Black pine: a leaning, bending trunk with flat cloud-like foliage pads.
	var base := _ground(x)
	var h := rng.randf_range(95.0, 135.0)
	var lean := rng.randf_range(-22.0, 22.0)
	var trunk := PackedVector2Array()
	for i in 7:
		var t := i / 6.0
		trunk.append(base + Vector2(lean * t + sin(t * PI * 1.5) * 8.0, -h * t))
	var shapes: Array = [[PaperDraw.band(trunk, 7.0), BARK]]
	var details: Array = []
	for i in 4:
		var t := 0.45 + i * 0.18
		var at := trunk[mini(roundi(t * 6.0), 6)]
		var side := -1.0 if i % 2 == 0 else 1.0
		var centre := at + Vector2(side * rng.randf_range(8.0, 18.0), rng.randf_range(-4.0, 4.0))
		shapes.append([PaperDraw.stick(at, centre, 3.0), BARK])
		var pad := Vector2(rng.randf_range(20.0, 30.0), rng.randf_range(7.0, 10.0)) * (1.15 - t * 0.4)
		var green := PINE_GREEN.lightened(rng.randf_range(-0.05, 0.12))
		shapes.append([PaperDraw.ellipse(centre, pad, 16), green])
		details.append([centre + Vector2(-pad.x * 0.6, pad.y * 0.3), centre + Vector2(pad.x * 0.6, pad.y * 0.3),
			green.darkened(0.35), 1.2])
	return [shapes, details, base]


func _cedar(rng: RandomNumberGenerator, x: float) -> Array:
	# Sugi cedar: tall and narrow, stacked layers.
	var base := _ground(x)
	var h := rng.randf_range(120.0, 160.0)
	var shapes: Array = [[PaperDraw.stick(base, base + Vector2(0, -h * 0.4), 6.0), BARK]]
	var green := CEDAR_GREEN.lightened(rng.randf_range(-0.05, 0.1))
	for i in 4:
		var y0 := -h * (0.22 + i * 0.19)
		var half := 20.0 - i * 3.5
		shapes.append([PackedVector2Array([
			base + Vector2(-half, y0), base + Vector2(0, y0 - h * 0.3), base + Vector2(half, y0)]),
			green.lightened(i * 0.04)])
	return [shapes, [], base]


func _building(rng: RandomNumberGenerator, x: float, storehouse: bool) -> Array:
	var base := _ground(x)
	var shapes: Array = []
	var details: Array = []
	if storehouse:
		# Kura: white plaster storehouse on a dark base, tiled roof.
		var w := rng.randf_range(30.0, 36.0)
		var h := rng.randf_range(42.0, 50.0)
		shapes.append([PaperDraw.rect(base.x - w / 2, base.y - h, w, h), WALL])
		shapes.append([PaperDraw.rect(base.x - w / 2, base.y - 12, w, 12), TIMBER])
		shapes.append([PaperDraw.rect(base.x - 4, base.y - h + 12, 8, 8), TIMBER])
		shapes.append([_tiled_roof(base + Vector2(0, -h), w + 12, 14), TILE])
	else:
		# Minka farmhouse: timber-framed walls under a steep thatched roof.
		var w := rng.randf_range(56.0, 74.0)
		var h := rng.randf_range(24.0, 30.0)
		var left := base.x - w / 2
		shapes.append([PaperDraw.rect(left, base.y - h, w, h), WALL])
		for i in 4:
			var px := left + w * i / 3.0
			details.append([Vector2(px, base.y - h), Vector2(px, base.y), TIMBER, 2.0])
		details.append([Vector2(left, base.y - h * 0.55), Vector2(left + w, base.y - h * 0.55), TIMBER, 1.5])
		shapes.append([PaperDraw.rect(left + w * 0.38, base.y - h * 0.8, w * 0.22, h * 0.8), TIMBER])
		var roof_h := rng.randf_range(34.0, 44.0)
		var eave := base.y - h + 2
		shapes.append([PackedVector2Array([
			Vector2(left - 9, eave), Vector2(left + w * 0.3, eave - roof_h),
			Vector2(left + w * 0.7, eave - roof_h), Vector2(left + w + 9, eave)]),
			THATCH.lightened(rng.randf_range(-0.06, 0.08))])
		shapes.append([PaperDraw.rect(left + w * 0.3 - 2, eave - roof_h - 4, w * 0.4 + 4, 5), TIMBER])
		for i in 3:
			var y := eave - roof_h * (0.25 + i * 0.25)
			var inset := (roof_h * (0.25 + i * 0.25)) / roof_h * w * 0.3
			details.append([Vector2(left - 9 + inset + 4, y), Vector2(left + w + 9 - inset - 4, y),
				THATCH.darkened(0.3), 1.0])
	return [shapes, details, base]


## A tiled roof with gently upturned eaves.
func _tiled_roof(top_of_wall: Vector2, width: float, height: float) -> PackedVector2Array:
	var half := width / 2
	return PackedVector2Array([
		top_of_wall + Vector2(-half - 3, -4), top_of_wall + Vector2(-half + 4, 0),
		top_of_wall + Vector2(half - 4, 0), top_of_wall + Vector2(half + 3, -4),
		top_of_wall + Vector2(half * 0.45, -height), top_of_wall + Vector2(-half * 0.45, -height)])
