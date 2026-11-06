class_name TroopType
extends Resource
## One kind of soldier (ashigaru, samurai, archer, skirmisher).
## Only the look lives here for now. Combat values arrive with the fighting step.

enum Weapon { SPEAR, SWORD, BOW, SHORT_SWORD }
enum Headgear { JINGASA, KABUTO, HACHIMAKI }

@export var display_name: String = "Ashigaru"
@export var weapon: Weapon = Weapon.SPEAR
@export var headgear: Headgear = Headgear.JINGASA
## Heavy armour adds shoulder plates, armoured legs and lacing.
@export var heavy_armour: bool = false
## Main colour of the soldier's coat or armour.
@export var body_colour: Color = Color("3b4a6b")
## Overall figure size. 1.0 is a normal ashigaru.
@export_range(0.7, 1.4) var figure_scale: float = 1.0
