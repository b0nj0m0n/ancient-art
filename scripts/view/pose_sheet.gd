class_name PoseSheet
extends Control
## Developer view: every pose of one rigged unit, large and labelled, plus the
## unit moving through its demo animation. Opened with the Poses button.

@export_file("*.json") var rig_path: String = "res://art/units/ashigaru_spearman/rig.json"
## Animation played in the last cell.
@export var demo_animation: String = "demo"

## Room one figure needs, in figure units. Upright spears are allowed to poke
## above their cell so the bodies can be drawn larger.
const CELL_HEIGHT := 780.0
const CELL_WIDTH := 640.0
const COLUMNS := 4
const TOP_MARGIN := 56.0
const LABEL_HEIGHT := 28.0

var _figure: RiggedFigure
var _time: float = 0.0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_figure = RiggedFigure.new(rig_path)
	_figure.side_colour = Palette.VERMILION


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_time += delta
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Palette.PAPER)
	if _figure == null or not _figure.has_parts():
		return
	var names: Array = _figure.rig.poses.keys()
	var cells := names.size() + 1
	var rows := ceili(cells / float(COLUMNS))
	var cell := Vector2(size.x / COLUMNS, (size.y - TOP_MARGIN) / rows)
	# Figure units to pixels.
	var s: float = minf(cell.x / CELL_WIDTH, (cell.y - LABEL_HEIGHT) / CELL_HEIGHT) / _figure.rig.unit_scale
	var font := ThemeDB.fallback_font
	for i in cells:
		var corner := Vector2(cell.x * (i % COLUMNS), TOP_MARGIN + cell.y * floori(i / float(COLUMNS)))
		var ground := corner.y + cell.y - LABEL_HEIGHT
		var feet := Vector2(corner.x + cell.x * 0.4, ground)
		var pose: Dictionary
		var label: String
		if i < names.size():
			label = str(names[i])
			pose = _figure.rig.poses[names[i]]
		else:
			label = demo_animation + " (moving)"
			pose = _figure.pose_at(demo_animation, _time)
		draw_line(Vector2(corner.x + 16.0, ground + 2.0), Vector2(corner.x + cell.x - 16.0, ground + 2.0),
			Color(Palette.INK, 0.25), 1.5)
		_figure.draw(self, Transform2D(0.0, Vector2(s, s), 0.0, feet), pose, Vector2(4, 5))
		draw_string(font, Vector2(corner.x, ground + 22.0), label, HORIZONTAL_ALIGNMENT_CENTER, cell.x, 18,
			Color(Palette.INK, 0.8))
