tool
class_name InvisibleTexture
extends SingleColorTexture


func _init() -> void:
	.set_color(Color.transparent)


func set_color(_color) -> void:
	push_warning("InvisibleTexture.color can’t be changed.")
