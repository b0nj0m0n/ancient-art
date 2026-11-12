extends Button
## Developer aid: shows or hides the pose sheet.

@export var sheet_path: NodePath = ^"../PoseSheet"


func _ready() -> void:
	pressed.connect(_toggle)


func _toggle() -> void:
	var sheet := get_node_or_null(sheet_path) as CanvasItem
	if sheet != null:
		sheet.visible = not sheet.visible
