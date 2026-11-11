class_name TroopType
extends Resource
## One kind of soldier (ashigaru, samurai, archer, skirmisher).
## Look and movement for now. Combat values arrive with the fighting step.

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

@export_group("Movement")
## Marching speed on level ground, in field units per second.
## The field is 1280 units wide.
@export var march_speed: float = 34.0
## Stays where it was placed instead of marching at the start
## (archers, until ranged combat gives them something to do from range).
@export var holds_position: bool = false
