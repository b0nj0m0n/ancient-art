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
## A line of words near the bottom that teaches the controls. It goes quiet
## after the player's first order.
var hint: Label
var _orders_given: int = 0
## When a passing message (such as a refused order) should disappear, in ms.
var _hide_hint_at: int = -1


func reset(b: Battle) -> void:
	battle = b
	if not retreat_button.pressed.is_connected(_on_retreat):
		retreat_button.pressed.connect(_on_retreat)
	_orders_given = 0
	_select(null)
	var mine := battle.side_setup(battle.setup.player_side).side_name.to_lower()
	var where := "right" if battle.setup.player_side == Battle.RIGHT else "left"
	_say("You command the %s, on the %s. Tap one of your squads." % [mine, where])


func _process(_delta: float) -> void:
	if battle != null and battle.is_over():
		_say("")
	if _hide_hint_at > 0 and Time.get_ticks_msec() > _hide_hint_at:
		_hide_hint_at = -1
		_say("")
	army.show_player_squads = _orders_given == 0 and army.selected == null and battle != null and not battle.is_over()


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
			_ordered()
			_select(null)
		else:
			_refused()
	elif _orders_given == 0:
		_say("That's the enemy. Tap one of your own squads first.")


func _on_retreat() -> void:
	if army.selected == null:
		return
	if battle.order_retreat(army.selected):
		_ordered()
		_select(null)
	else:
		_refused()


func _select(squad: Squad) -> void:
	if squad != null and (squad.standing().is_empty() or squad.order == Squad.Order.RETREAT):
		squad = null
	army.selected = squad
	retreat_button.visible = squad != null
	if _orders_given == 0:
		if squad != null:
			_say("Now tap an enemy squad to attack, or press Retreat.")
		elif battle != null:
			_say("Tap one of your squads to give it an order.")


func _ordered() -> void:
	_orders_given += 1
	_say("")


func _refused() -> void:
	bar.refuse()
	_say("The messengers are still running. Wait for the brush stroke to refill.")
	if _orders_given > 0:
		_hide_hint_at = Time.get_ticks_msec() + 3000


func _say(text: String) -> void:
	if hint == null:
		return
	hint.text = text
	hint.visible = text != ""


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
