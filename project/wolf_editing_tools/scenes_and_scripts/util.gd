extends Object
class_name Util


static func texture_to_uwmf(texture : Texture) -> String:
	var SingleColorTextureType = load("res://wolf_editing_tools/scenes_and_scripts/resource_types/single_color_texture.gd")
	if texture is SingleColorTextureType:
		return texture.to_uwmf()
	else:
		return "%s" % [texture.resource_path.get_basename().get_file()]


func _init() -> void:
	push_warning("Util is a utillity class. Why are you constructing it?")
