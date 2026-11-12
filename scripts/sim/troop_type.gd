class_name TroopType
extends Resource
## One kind of soldier (ashigaru, samurai, archer, skirmisher).
## Look, movement and fighting style. Matchups come from how these values
## interact (reach, armour, skill, position), never from a lookup table.

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
## Rigged cut-paper art for this troop (a rig.json made by tools/artgen).
## Leave empty to draw the simple built-in figure instead.
@export_file("*.json") var rig_path: String = ""

@export_group("Movement")
## Marching speed on level ground, in field units per second.
## The field is 1280 units wide.
@export var march_speed: float = 34.0
## Stays where it was placed instead of marching at the start
## (archers, until ranged combat gives them something to do from range).
@export var holds_position: bool = false

@export_group("Fighting")
## How far the weapon reaches, in field units.
@export var reach: float = 12.0
## Long weapons are clumsy up close. An enemy nearer than this is "inside the
## weapon", and blows land less often (see close_effectiveness).
@export var close_range: float = 0.0
## Hit chance multiplier against an enemy inside close_range.
@export_range(0.0, 1.0) var close_effectiveness: float = 1.0
## The distance this troop tries to fight at. Spearmen brace at spear's length;
## swordsmen push in close.
@export var preferred_range: float = 10.0
## Seconds between blows.
@export var attack_interval: float = 1.2
## Damage of a clean blow, before armour.
@export var damage: float = 30.0
## Share of each blow the armour absorbs (0 = none, 0.6 = heavy).
@export_range(0.0, 0.9) var armour: float = 0.1

@export_group("Hidden stat ranges")
## Each soldier's hidden stats are rolled between these, from the battle seed.
@export var skill_range: Vector2 = Vector2(0.35, 0.55)
@export var toughness_range: Vector2 = Vector2(70.0, 90.0)
@export var pace_range: Vector2 = Vector2(0.9, 1.1)
