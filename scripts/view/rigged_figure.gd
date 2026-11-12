class_name RiggedFigure
extends RefCounted
## A soldier drawn from rigged cut-paper parts made by tools/artgen.
##
## A unit folder (art/units/<unit>/) holds rig.json and one texture per body
## part. Each part hangs off a parent at a pivot; a pose is a rotation per
## part. To upgrade the art later, replace the files that rig.json points at
## (SVG or PNG): nothing here needs to change.
##
## Part coordinates are "figure units": feet at (0, 0), facing right, up is -y,
## 10 figure units = 1 game unit (see units_per_game_unit in rig.json).

## SVG parts are rasterised at this scale when first loaded, with mipmaps, so
## they stay sharp on high-resolution phones.
const RASTER_SCALE := 0.5
const GOLD := Color("c9a227")

## One loaded unit, shared by every soldier of that type.
class Rig:
	var names: PackedStringArray = []
	var parents: PackedInt32Array = []
	var pivots: PackedVector2Array = []
	var origins: PackedVector2Array = []
	var sizes: PackedVector2Array = []
	var tints: PackedStringArray = []
	var textures: Array[Texture2D] = []
	var edges: Array[Texture2D] = []
	## Part indices sorted so parents come before children.
	var solve_order: PackedInt32Array = []
	## Part indices sorted back to front.
	var draw_order: PackedInt32Array = []
	var poses: Dictionary = {}
	var animations: Dictionary = {}
	## Game units per figure unit.
	var unit_scale: float = 0.1

static var _rigs: Dictionary = {}

var rig: Rig
var side_colour := Color.WHITE
var mon_colour := Color.WHITE
## Slight per-soldier shade so a squad is not a row of clones.
var shade := Color.WHITE
var sway_phase: float = 0.0
var sway_speed: float = 1.0
var scale: float = 1.0
## Offsets this soldier's animation clock so a squad does not move in step.
var time_offset: float = 0.0


func _init(rig_path: String, soldier: Soldier = null, side_def: SideSetup = null) -> void:
	rig = load_rig(rig_path)
	if soldier == null:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = soldier.look_seed
	var v := rng.randf_range(0.9, 1.0)
	shade = Color(v, v, v)
	scale = soldier.squad.troop.figure_scale * rng.randf_range(0.94, 1.06)
	sway_phase = rng.randf_range(0.0, TAU)
	sway_speed = rng.randf_range(0.8, 1.3)
	time_offset = rng.randf_range(0.0, 3.0)
	if side_def != null:
		# The commander carries a gold banner with the side's colour as its crest.
		side_colour = GOLD if soldier.is_commander else side_def.banner_colour
		mon_colour = side_def.banner_colour if soldier.is_commander else side_def.mon_colour


## Loads a unit once and keeps it. Returns an empty rig if the file is missing.
static func load_rig(path: String) -> Rig:
	if _rigs.has(path):
		return _rigs[path]
	var r := Rig.new()
	_rigs[path] = r
	var data: Variant = _read_json(path)
	if not data is Dictionary:
		push_error("RiggedFigure: cannot read rig %s" % path)
		return r
	var folder := path.get_base_dir()
	r.unit_scale = 1.0 / float(data.get("units_per_game_unit", 10.0))
	r.poses = data.get("poses", {})
	r.animations = data.get("animations", {})
	var parts: Array = data.get("parts", [])
	var index := {}
	for i in parts.size():
		index[parts[i]["name"]] = i
	for i in parts.size():
		var p: Dictionary = parts[i]
		r.names.append(p["name"])
		r.parents.append(index.get(p["parent"], -1))
		r.pivots.append(Vector2(p["pivot"][0], p["pivot"][1]))
		r.origins.append(Vector2(p["texture_origin"][0], p["texture_origin"][1]))
		r.sizes.append(Vector2(p["size"][0], p["size"][1]))
		var tint: Variant = p.get("tint")
		r.tints.append(tint if tint is String else "")
		r.textures.append(_load_texture(folder.path_join(p["texture"])))
		r.edges.append(_load_texture(folder.path_join(p.get("edge_texture", p["texture"]))))
	# Parents before children, so each part can build on its parent's transform.
	var placed := {}
	while r.solve_order.size() < parts.size():
		var before := r.solve_order.size()
		for i in parts.size():
			if not placed.has(i) and (r.parents[i] < 0 or placed.has(r.parents[i])):
				placed[i] = true
				r.solve_order.append(i)
		if r.solve_order.size() == before:
			push_error("RiggedFigure: parent loop in %s" % path)
			break
	var order: Array = range(parts.size())
	order.sort_custom(func(a: int, b: int) -> bool: return float(parts[a]["z"]) < float(parts[b]["z"]))
	r.draw_order = PackedInt32Array(order)
	return r


static func _read_json(path: String) -> Variant:
	if FileAccess.file_exists(path):
		return JSON.parse_string(FileAccess.get_file_as_string(path))
	# In an exported build the file may only exist as an imported JSON resource.
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res is JSON:
			return (res as JSON).data
	return null


## SVG files are drawn fresh at RASTER_SCALE; anything else (painted PNG parts
## later on) loads as a normal imported texture.
static func _load_texture(path: String) -> Texture2D:
	if path.get_extension().to_lower() == "svg" and FileAccess.file_exists(path):
		var img := Image.new()
		if img.load_svg_from_string(FileAccess.get_file_as_string(path), RASTER_SCALE) == OK:
			img.generate_mipmaps()
			return ImageTexture.create_from_image(img)
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	push_error("RiggedFigure: missing part texture %s" % path)
	return null


func has_parts() -> bool:
	return rig.names.size() > 0


## The pose at time t of a named animation (see "animations" in rig.json).
## Each step is [pose, seconds]: the figure moves from that pose to the next.
func pose_at(animation: String, t: float) -> Dictionary:
	var steps: Array = rig.animations.get(animation, [])
	if steps.is_empty():
		return rig.poses.get(animation, {})
	var total := 0.0
	for s in steps:
		total += float(s[1])
	t = fposmod(t + time_offset, total)
	for i in steps.size():
		var d := float(steps[i][1])
		if t < d:
			var a: Dictionary = rig.poses.get(steps[i][0], {})
			var b: Dictionary = rig.poses.get(steps[(i + 1) % steps.size()][0], {})
			return blend(a, b, smoothstep(0.0, 1.0, t / d))
		t -= d
	return {}


static func blend(a: Dictionary, b: Dictionary, w: float) -> Dictionary:
	var out := {}
	for k in a:
		out[k] = lerpf(float(a[k]), float(b.get(k, 0.0)), w)
	for k in b:
		if not a.has(k):
			out[k] = lerpf(0.0, float(b[k]), w)
	return out


## Draws the figure. xf maps game units (feet at the origin) onto the canvas.
func draw(ci: CanvasItem, xf: Transform2D, pose: Dictionary, shadow: Vector2 = Vector2(3, 4)) -> void:
	var n := rig.names.size()
	if n == 0:
		return
	var root := Transform2D(deg_to_rad(float(pose.get("root", 0.0))),
		Vector2(float(pose.get("root_x", 0.0)), float(pose.get("root_y", 0.0))))
	var world: Array[Transform2D] = []
	world.resize(n)
	for i in rig.solve_order:
		var parent_xf: Transform2D = root if rig.parents[i] < 0 else world[rig.parents[i]]
		var angle := deg_to_rad(float(pose.get(rig.names[i], 0.0)))
		world[i] = parent_xf * Transform2D(angle, rig.pivots[i]) * Transform2D(0.0, -rig.pivots[i])
	var to_canvas := xf * Transform2D(0.0, Vector2(rig.unit_scale, rig.unit_scale), 0.0, Vector2.ZERO)
	var placed: Array[Transform2D] = []
	placed.resize(n)
	for i in n:
		placed[i] = to_canvas * world[i] * Transform2D(0.0, rig.origins[i])
	# 1. Shadow, as if the paper stands slightly off the page.
	for i in rig.draw_order:
		if rig.edges[i] != null:
			ci.draw_set_transform_matrix(Transform2D(0.0, shadow) * placed[i])
			ci.draw_texture_rect(rig.edges[i], Rect2(Vector2.ZERO, rig.sizes[i]), false, Palette.CUT_SHADOW)
	# 2. Pale cut edge around the whole silhouette.
	for i in rig.draw_order:
		if rig.edges[i] != null:
			ci.draw_set_transform_matrix(placed[i])
			ci.draw_texture_rect(rig.edges[i], Rect2(Vector2.ZERO, rig.sizes[i]), false, PaperDraw.EDGE_COLOUR)
	# 3. The parts themselves, back to front.
	for i in rig.draw_order:
		if rig.textures[i] != null:
			ci.draw_set_transform_matrix(placed[i])
			ci.draw_texture_rect(rig.textures[i], Rect2(Vector2.ZERO, rig.sizes[i]), false, _tint(rig.tints[i]))
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


func _tint(kind: String) -> Color:
	match kind:
		"side":
			return side_colour
		"mon":
			return mon_colour
	return shade
