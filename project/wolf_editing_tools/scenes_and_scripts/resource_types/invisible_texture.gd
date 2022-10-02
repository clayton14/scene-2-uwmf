tool
class_name InvisibleTexture
extends SingleColorTexture


func initialize() -> void:
	._set_color_no_verify(Color.transparent)


func set_color(_color) -> void:
	push_warning("InvisibleTexture.color can’t be changed.")


func to_uwmf() -> String:
	return "-"


static func make_color_a_property() -> bool:
	return false
