extends Node

const Tile := preload("res://wolf_editing_tools/scenes_and_scripts/map/tile.gd")
const Wad := preload("res://wolf_editing_tools/scenes_and_scripts/file_formats/wad.gd")
const NAMESPACE := "Wolf3D";

# This will be the name of the header lump [1] when the map is exported. It also gets used as the
# basename of the WAD file.
#
# [1]: <https://github.com/rheit/zdoom/blob/d44976175256f3db8ec61cca40f1267cca68967d/specs/udmf.txt#L161>
export var internal_name := "MAP01"
export var automap_name : String = internal_name
# Are there any ports that even support a different value?
export var tile_size := 64


static func property_assignment_statement(property: String, value) -> String:
	# I’m writting property names in all uppercase.
	#
	# When you encode English text in UTF-8, the majority of the bits will probably be zero. Most
	# characters that are used when writting English are in ASCII. All ASCII characters (when
	# encoded using UTF-8) have their eighth bit set to zero.
	#
	# Additionally, all uppercase letters have their sixth bit set to zero. All lowercase letters
	# have their sixth bit set to one.
	#
	# Using uppercase letters means that there will be less variation in the data (most of it will
	# probably be zeros). Less variation probably means better compression.
	return '%s=%s;' % [property.to_upper(), var2str(value)]


static func named_block(name : String, contents : Dictionary) -> String:
	var return_value := name + "{"
	for key in contents:
		# Take a look at the comment in convert_to_uwmf for why I’m doing it
		# like this.
		return_value += property_assignment_statement(key.to_upper(), contents[key])
	return_value += "}"
	return return_value


func size() -> Vector3:
	var return_value := Vector3.ZERO
	for child in get_children():
		if child is Tile:
			var position : Vector3 = child.uwmf_position()
			return_value.x = max(return_value.x, position.x + 1)
			return_value.y = max(return_value.y, position.y + 1)
			return_value.z = max(return_value.z, position.z + 1)
	return return_value


func convert_to_uwmf() -> String:
	var size := size()
	return (
		property_assignment_statement("namespace", NAMESPACE)
		+ property_assignment_statement("name", automap_name)
		+ property_assignment_statement("tileSize", tile_size)
		+ property_assignment_statement("width", int(size.x))
		+ property_assignment_statement("height", int(size.y))
	)


# For the moment, I’m going to make _ready() export the map.
func _ready() -> void:
	var wad := Wad.new()
	var lumps := [
		Wad.Lump.new(internal_name, PoolByteArray()),
		Wad.Lump.new("TEXTMAP", convert_to_uwmf().to_utf8()),
		Wad.Lump.new("ENDMAP", PoolByteArray()),
	]
	assert(wad.set_lumps(lumps), "Setting lumps failed.")
	assert(wad.save("user://%s.WAD" % [internal_name]) == OK, "Saving WAD failed.")
