#tool
class_name SingleColorTexture
extends ImageTexture


signal color_changed


func _init() -> void:
	set_color(Color.white)


func _set_color_no_verify(new_color : Color) -> void:
	var new_image = Image.new()
	new_image.create(1, 1, false, Util.TILE_IMAGE_FORMAT)
	new_image.lock()
	new_image.set_pixelv(Vector2.ZERO, new_color)
	new_image.unlock()
	create_from_image(new_image)
	emit_signal("color_changed")


func set_color(new_color : Color) -> void:
	if new_color.a != 1.0:
		push_warning("The UWMF doesn’t support transparent color textures. Resetting alpha to 1.0…")
		new_color.a = 1.0
	_set_color_no_verify(new_color)


func get_color() -> Color:
	var return_value : Color
	var data := get_data()
	data.lock()
	return_value = data.get_pixelv(Vector2.ZERO)
	data.unlock()
	return return_value


static func color_usage() -> int:
	return PROPERTY_USAGE_DEFAULT


func _get_property_list() -> Array:
	return [
		{
			"name" : "color",
			"type" : typeof(Color.white),
			"usage" : color_usage()
		}
	]


func _get(property):
	if property is String and property == "color":
		return get_color()
	else:
		return null


func _set(property, value) -> bool:
	if property is String and property == "color":
		if value is Color:
			set_color(value)
		else:
			push_error("“%s” is not a Color." % [value])
	return false
