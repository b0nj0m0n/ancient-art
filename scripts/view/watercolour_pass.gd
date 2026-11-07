extends ColorRect
## The full-screen watercolour pass (shaders/watercolour.gdshader).
## Keeps the shader told how big the game canvas is, so the paper grain and
## the boil stay the same size on every phone.


func _ready() -> void:
	get_viewport().size_changed.connect(_resize)
	_resize()


func _resize() -> void:
	var size := get_viewport().get_visible_rect().size
	(material as ShaderMaterial).set_shader_parameter("canvas_size", size)
