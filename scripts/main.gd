extends Node2D
## Boots a skirmish: builds the battle from its setup and hands it to the views.

@export var setup: SkirmishSetup

@onready var _field: FieldView = $Field
@onready var _hillside: HillsideView = $Field/Hillside
@onready var _scenery: SceneryView = $Field/Scenery
@onready var _army: ArmyView = $Field/Army


func _ready() -> void:
	_field.field_width = setup.terrain.field_width
	_hillside.terrain = setup.terrain
	_scenery.build(setup)
	_army.show_battle(Battle.new(setup))
