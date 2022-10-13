extends Reference


var texture_ceiling : Texture = default_texture_ceiling() setget set_texture_ceiling
var texture_floor : Texture = default_texture_floor() setget set_texture_floor


# These values were coppied from ecwolf.pk3/mapinfo/wolfcommon.txt
static func default_texture_ceiling() -> SingleColorTexture:
	return SingleColorTexture.from_color(Color("#383838"))


static func default_texture_floor() -> SingleColorTexture:
	return SingleColorTexture.from_color(Color("#717171"))


func set_texture_ceiling(new_texture : Texture) -> void:
	if new_texture == null:
		new_texture = default_texture_ceiling()
	texture_ceiling = new_texture


func set_texture_floor(new_texture : Texture) -> void:
	if new_texture == null:
		new_texture = default_texture_floor()
	texture_floor = new_texture


func to_uwmf() -> String:
	return Util.named_block(
		"sector",
		{
			"textureCeiling" : Util.texture_to_uwmf(texture_ceiling),
			"textureFloor" : Util.texture_to_uwmf(texture_floor)
		}
	)
