#tool
class_name InvisibleTexture
extends SingleColorTexture


func _init() -> void:
	._set_color_no_verify(Color.transparent)


func set_color(_color) -> void:
	push_warning("InvisibleTexture.color can’t be changed.")


func to_uwmf() -> String:
	return '"-"'


static func color_usage() -> int:
	return .color_usage() & ~PROPERTY_USAGE_STORAGE
