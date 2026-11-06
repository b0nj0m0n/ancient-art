class_name SoldierFigure
extends RefCounted
## Builds one soldier's cut-paper figure in local space: feet at (0, 0),
## facing right (+x), up is -y. The view flips it for the right-hand side.
## Every soldier gets small personal touches from their look seed so you can
## tell people apart.

const SKIN_TONES: Array[Color] = [Color("e8c39e"), Color("d9ad84"), Color("c9996f")]
const SASH_COLOURS: Array[Color] = [
	Color("c9b458"), Color("8a4f7d"), Color("5e7f8c"), Color("a6533a"), Color("e6e0cf"),
]
const LACQUER := Color("2b2622")
const STEEL := Color("b9bcbd")
const WOOD := Color("6b4a2f")
const GOLD := Color("c9a227")

var shapes: Array = []
var details: Array = []
## Gentle idle sway, so the paper figures feel alive.
var sway_phase: float = 0.0
var sway_speed: float = 1.0
var scale: float = 1.0


func _init(soldier: Soldier, side_def: SideSetup) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = soldier.look_seed
	var troop := soldier.squad.troop
	var skin: Color = SKIN_TONES[rng.randi_range(0, SKIN_TONES.size() - 1)]
	var sash: Color = SASH_COLOURS[rng.randi_range(0, SASH_COLOURS.size() - 1)]
	var body := troop.body_colour.lightened(rng.randf_range(-0.08, 0.1))
	scale = troop.figure_scale * rng.randf_range(0.94, 1.06)
	sway_phase = rng.randf_range(0.0, TAU)
	sway_speed = rng.randf_range(0.8, 1.3)
	var tilt := rng.randf_range(-3.0, 3.0)

	_sashimono(soldier, side_def, troop)
	if troop.weapon == TroopType.Weapon.BOW:
		_quiver()
	_legs(body, troop.heavy_armour)
	_torso(body, sash, troop.heavy_armour)
	_head(skin, troop.headgear, soldier.is_commander, side_def)
	_weapon(troop.weapon, tilt)


func _sashimono(soldier: Soldier, side_def: SideSetup, troop: TroopType) -> void:
	# Back banner on a pole. The commander's is taller and gold.
	var top := -64.0 if soldier.is_commander else -56.0
	if troop.heavy_armour:
		top -= 4.0
	shapes.append([PaperDraw.stick(Vector2(-6, -24), Vector2(-6, top), 1.6), WOOD])
	var flag_colour := GOLD if soldier.is_commander else side_def.banner_colour
	var mon_colour := side_def.banner_colour if soldier.is_commander else side_def.mon_colour
	shapes.append([PaperDraw.rect(-17, top, 11, 15), flag_colour])
	shapes.append([PaperDraw.ellipse(Vector2(-11.5, top + 7.5), Vector2(3, 3), 10), mon_colour])


func _quiver() -> void:
	shapes.append([PaperDraw.stick(Vector2(-7, -14), Vector2(-10, -36), 5.0), WOOD.darkened(0.2)])
	for i in 3:
		var base := Vector2(-9.5 - i * 1.2, -36)
		shapes.append([PaperDraw.stick(base, base + Vector2(-1.5, -6), 2.0), Color("e6e0cf")])


func _legs(body: Color, heavy: bool) -> void:
	var leg := body.darkened(0.35)
	shapes.append([PaperDraw.rect(-5, -16, 4, 16), leg])
	shapes.append([PaperDraw.rect(1, -16, 4, 16), leg])
	if heavy:
		# Shin guards (suneate) and thigh guards (haidate).
		shapes.append([PaperDraw.rect(-5.5, -9, 5, 7), STEEL.darkened(0.3)])
		shapes.append([PaperDraw.rect(0.5, -9, 5, 7), STEEL.darkened(0.3)])
		shapes.append([PaperDraw.rect(-7, -18, 14, 6), body.darkened(0.15)])
	shapes.append([PaperDraw.rect(-6, -1.5, 5, 2), LACQUER])
	shapes.append([PaperDraw.rect(1, -1.5, 6, 2), LACQUER])


func _torso(body: Color, sash: Color, heavy: bool) -> void:
	var w := 8.0 if heavy else 7.0
	shapes.append([PackedVector2Array([
		Vector2(-w, -31), Vector2(w, -31), Vector2(w - 1, -15), Vector2(-w + 1, -15)]), body])
	shapes.append([PaperDraw.rect(-w + 1, -18, (w - 1) * 2, 3), sash])
	if heavy:
		# Shoulder plates (sode) and lacing bands across the cuirass.
		shapes.append([PaperDraw.rect(-w - 3, -31, 5, 9), body.darkened(0.2)])
		shapes.append([PaperDraw.rect(w - 2, -31, 5, 9), body.darkened(0.2)])
		for y in [-27.0, -23.0, -20.0]:
			details.append([Vector2(-w + 1, y), Vector2(w - 1, y), GOLD.darkened(0.2), 1.0])
	# Forward arm.
	shapes.append([PaperDraw.stick(Vector2(3, -29), Vector2(9, -21), 4.0), body.darkened(0.1)])


func _head(skin: Color, headgear: TroopType.Headgear, commander: bool, side_def: SideSetup) -> void:
	shapes.append([PaperDraw.ellipse(Vector2(0.5, -36), Vector2(5, 5.5)), skin])
	details.append([Vector2(3, -37), Vector2(4.2, -37), LACQUER, 1.2])  # eye
	match headgear:
		TroopType.Headgear.JINGASA:
			shapes.append([PackedVector2Array([
				Vector2(-11, -37), Vector2(0.5, -45), Vector2(12, -37), Vector2(0.5, -38.5)]), LACQUER])
			shapes.append([PaperDraw.ellipse(Vector2(0.5, -40.5), Vector2(1.6, 1.4), 8), side_def.mon_colour])
		TroopType.Headgear.KABUTO:
			shapes.append([PackedVector2Array([
				Vector2(-8, -34), Vector2(-6, -42), Vector2(0.5, -45), Vector2(7, -42),
				Vector2(8, -38), Vector2(5, -39), Vector2(-4, -39), Vector2(-5, -33)]), LACQUER])
			# Neck guard (shikoro).
			shapes.append([PackedVector2Array([
				Vector2(-5, -38), Vector2(-11, -31), Vector2(-7, -30), Vector2(-3, -35)]), LACQUER])
			# Antler crest (kuwagata); gold, larger for the commander.
			var h := 9.0 if commander else 6.0
			shapes.append([PaperDraw.stick(Vector2(1.5, -44), Vector2(-1.5, -44 - h), 1.8), GOLD])
			shapes.append([PaperDraw.stick(Vector2(2.5, -44), Vector2(6, -44 - h), 1.8), GOLD])
		TroopType.Headgear.HACHIMAKI:
			shapes.append([PaperDraw.ellipse(Vector2(0, -39.5), Vector2(5.2, 3), 10), Color("1f1c19")])
			shapes.append([PaperDraw.rect(-5, -39, 10.5, 2.4), Color("ece6d6")])
			shapes.append([PaperDraw.stick(Vector2(-5, -38), Vector2(-10, -35), 1.6), Color("ece6d6")])


func _weapon(weapon: TroopType.Weapon, tilt: float) -> void:
	match weapon:
		TroopType.Weapon.SPEAR:
			# Long yari, held upright, leaning forward a touch.
			var foot := Vector2(9, 2)
			var top := Vector2(13 + tilt, -86)
			shapes.append([PaperDraw.stick(foot, top, 1.8), WOOD])
			var dir := (top - foot).normalized()
			var n := dir.orthogonal() * 2.2
			shapes.append([PackedVector2Array([top + n, top + dir * 9.0, top - n]), STEEL])
		TroopType.Weapon.SWORD:
			# Katana raised forward.
			var hand := Vector2(9, -22)
			var tip := Vector2(24, -46 + tilt)
			var dir := (tip - hand).normalized()
			shapes.append([PaperDraw.stick(hand - dir * 6.0, hand, 2.4), LACQUER])
			shapes.append([PaperDraw.stick(hand, tip, 1.8), STEEL])
			shapes.append([PaperDraw.stick(hand - dir.orthogonal() * 2.5, hand + dir.orthogonal() * 2.5, 1.6), GOLD])
		TroopType.Weapon.SHORT_SWORD:
			var hand := Vector2(9, -21)
			shapes.append([PaperDraw.stick(hand, Vector2(19, -32 + tilt), 1.8), STEEL])
		TroopType.Weapon.BOW:
			# Yumi: tall and asymmetric, the grip below the middle.
			var pts := PackedVector2Array()
			for i in 13:
				var t := i / 12.0
				var y := lerpf(-74.0, 6.0, t)
				var bulge := sin(t * PI) * 7.0
				pts.append(Vector2(10 + bulge, y))
			shapes.append([PaperDraw.band(pts, 2.0), WOOD.darkened(0.3)])
			details.append([pts[0], pts[pts.size() - 1], Color("e6e0cf"), 0.8])
