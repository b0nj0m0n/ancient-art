class_name PaperDraw
## Helpers for the cut-paper look: each figure is a set of flat paper shapes,
## drawn with a soft shadow, then an ink outline, then the colour fill
## (woodblock-print style; see docs/art.md).
##
## A "shape" is [PackedVector2Array polygon, Color].
## A "detail" is [Vector2 from, Vector2 to, Color, float width], an ink line
## drawn on top with no border (lacing, bow strings, roof lines).

const EDGE_COLOUR := Palette.INK


static func draw_figure(ci: CanvasItem, shapes: Array, details: Array, xf: Transform2D,
		edge: float = 2.0, shadow: Vector2 = Vector2(3, 4)) -> void:
	var placed: Array = []
	for s in shapes:
		placed.append([xf * (s[0] as PackedVector2Array), s[1]])
	# 1. Shadow, as if the paper stands slightly off the page.
	for s in placed:
		var poly: PackedVector2Array = s[0]
		var shifted := PackedVector2Array()
		for p in poly:
			shifted.append(p + shadow)
		ci.draw_colored_polygon(shifted, Palette.CUT_SHADOW)
	# 2. Ink outline around the whole silhouette.
	if edge > 0.0:
		for s in placed:
			var poly: PackedVector2Array = s[0]
			var closed := poly.duplicate()
			closed.append(poly[0])
			ci.draw_polyline(closed, EDGE_COLOUR, edge * 2.0)
			for p in poly:
				ci.draw_circle(p, edge, EDGE_COLOUR)
	# 3. The paper itself.
	for s in placed:
		ci.draw_colored_polygon(s[0], s[1])
	# 4. Ink details.
	for d in details:
		ci.draw_line(xf * (d[0] as Vector2), xf * (d[1] as Vector2), d[2], d[3])


static func rect(x: float, y: float, w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h)])


static func ellipse(centre: Vector2, radius: Vector2, points: int = 14) -> PackedVector2Array:
	var poly := PackedVector2Array()
	for i in points:
		var a := TAU * i / points
		poly.append(centre + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	return poly


## A straight stick of the given width from a to b (spear shafts, poles, blades).
static func stick(a: Vector2, b: Vector2, width: float) -> PackedVector2Array:
	var n := (b - a).normalized().orthogonal() * width * 0.5
	return PackedVector2Array([a + n, b + n, b - n, a - n])


## A curved band following a list of points (bows, tree trunks).
static func band(points: PackedVector2Array, width: float) -> PackedVector2Array:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in points.size():
		var prev := points[maxi(i - 1, 0)]
		var next := points[mini(i + 1, points.size() - 1)]
		var n := (next - prev).normalized().orthogonal() * width * 0.5
		left.append(points[i] + n)
		right.append(points[i] - n)
	right.reverse()
	return left + right
