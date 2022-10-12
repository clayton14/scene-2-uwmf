tool
class_name SingleColorTexture
extends ImageTexture


signal color_changed


# By default, subclasses call their parent’s _init(). We don’t want that here,
# so we’re putting the initialization code into a function that can be fully
# overridden. Idea taken from here:
# <https://github.com/godotengine/godot-proposals/issues/594#issuecomment-600643905>
func _init() -> void:
	initialize()


func initialize() -> void:
	set_color(Color.white)


static func from_color(color : Color):
	var SingleColorTextureType = load("res://wolf_editing_tools/scenes_and_scripts/resource_types/single_color_texture.gd")
	var return_value = SingleColorTextureType.new()
	return_value.set_color(color)
	return return_value

func _set_color_no_verify(new_color : Color) -> void:
	var new_image = Image.new()
	new_image.create(1, 1, false, Image.FORMAT_RGBA8)
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


func to_uwmf() -> String:
	return "#%s" % [get_color().to_html(false).to_upper()]


static func make_color_a_property() -> bool:
	return true


func _get_property_list() -> Array:
	if make_color_a_property():
		return [
			{
				"name" : "color",
				"type" : typeof(Color.white)
			}
		]
	else:
		return []


func _get(property):
	if make_color_a_property() and property is String and property == "color":
		return get_color()
	else:
		return null


func _set(property, value) -> bool:
	if make_color_a_property() and property is String and property == "color":
		if value is Color:
			set_color(value)
		else:
			push_error("“%s” is not a Color." % [value])
	return false
