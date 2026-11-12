extends Node2D
## Boots a skirmish: builds the battle from its setup, runs the simulation at
## its fixed tick rate, and hands it to the views.

@export var setup: SkirmishSetup
## Most ticks to catch up in one frame, so a slow frame can't snowball.
const MAX_TICKS_PER_FRAME := 5

@onready var _field: FieldView = $Field
@onready var _hillside: HillsideView = $Field/Hillside
@onready var _scenery: SceneryView = $Field/Scenery
@onready var _army: ArmyView = $Field/Army
@onready var _restart: Button = $HUD/Restart
@onready var _result: Label = $HUD/Result

var _battle: Battle
var _accumulator: float = 0.0


func _ready() -> void:
	_field.field_width = setup.terrain.field_width
	_hillside.terrain = setup.terrain
	_scenery.build(setup)
	_restart.pressed.connect(_start_battle)
	_start_battle()


func _start_battle() -> void:
	_battle = Battle.new(setup)
	_accumulator = 0.0
	_army.show_battle(_battle)
	_result.visible = false


func _process(delta: float) -> void:
	_accumulator += delta
	var ticks := 0
	while _accumulator >= _battle.dt and ticks < MAX_TICKS_PER_FRAME:
		_battle.tick()
		_accumulator -= _battle.dt
		ticks += 1
	if ticks == MAX_TICKS_PER_FRAME:
		_accumulator = 0.0
	_army.alpha = clampf(_accumulator / _battle.dt, 0.0, 1.0)
	if _battle.is_over() and not _result.visible:
		# Words, never numbers.
		var victor := _battle.side_setup(_battle.winner).side_name.to_lower()
		_result.text = "The field belongs to the %s" % victor
		_result.visible = true
