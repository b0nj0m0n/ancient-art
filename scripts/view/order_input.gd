class_name OrderInput
extends Node
## Turns taps into orders. Tap one of your squads to select it, then tap an
## enemy squad to attack it, or press Retreat. Every order spends the command
## bar; if the bar is too low, nothing happens and the bar flashes.
## Taps land generously around a squad (its soldiers and banner), sized for a thumb.

## Extra room around a squad that still counts as tapping it, in field units.
@export var tap_margin: float = 26.0

var battle: Battle
var army: ArmyView
var bar: CommandBarView
var retreat_button: Button


func reset(b: Battle) -> void:
	battle = b
	if not retreat_button.pressed.is_connected(_on_retreat):
		retreat_button.pressed.connect(_on_retreat)
	_select(null)


func _unhandled_input(event: InputEvent) -> void:
	if battle == null or battle.is_over():
		return
	var tap := event as InputEventMouseButton
	if tap == null or not tap.pressed or tap.button_index != MOUSE_BUTTON_LEFT:
		return
	var squad := _squad_at(army.get_local_mouse_position())
	get_viewport().set_input_as_handled()
	if squad == null:
		_select(null)
	elif battle.is_player_side(squad.side):
		_select(squad if squad != army.selected else null)
	elif army.selected != null:
		if battle.order_attack(army.selected, squad):
			army.flash(squad)
			_select(null)
		else:
			bar.refuse()


func _on_retreat() -> void:
	if army.selected == null:
		return
	if battle.order_retreat(army.selected):
		_select(null)
	else:
		bar.refuse()


func _select(squad: Squad) -> void:
	if squad != null and (squad.standing().is_empty() or squad.order == Squad.Order.RETREAT):
		squad = null
	army.selected = squad
	retreat_button.visible = squad != null


## The squad under a tap, or null. Prefers the squad whose centre is nearest.
func _squad_at(p: Vector2) -> Squad:
	var best: Squad = null
	var best_d := INF
	for q in battle.squads:
		var standing := q.standing()
		if standing.is_empty():
			continue
		var lo := INF
		var hi := -INF
		for s in standing:
			lo = minf(lo, s.x)
			hi = maxf(hi, s.x)
		var mid := (lo + hi) * 0.5
		var ground := army.ground_y(mid)
		if p.x < lo - tap_margin or p.x > hi + tap_margin:
			continue
		if p.y < ground - 170.0 or p.y > ground + 30.0:
			continue
		var d := absf(p.x - mid)
		if d < best_d:
			best_d = d
			best = q
	return best
