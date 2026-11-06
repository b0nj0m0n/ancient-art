class_name FieldView
extends Node2D
## Parent of everything drawn on the battlefield. Keeps the field centred
## horizontally and pinned to the bottom of the screen, so on wide phones the
## empty sky is cropped instead of the ground. Children draw in field units.

@export var field_width: float = 1280.0


func _ready() -> void:
	get_viewport().size_changed.connect(_centre)
	_centre()


func _centre() -> void:
	var vis := get_viewport().get_visible_rect()
	position.x = vis.position.x + (vis.size.x - field_width) * 0.5
	position.y = vis.end.y - HillsideView.FIELD_HEIGHT
