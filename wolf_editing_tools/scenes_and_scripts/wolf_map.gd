extends Node

const Wad := preload("res://wolf_editing_tools/scenes_and_scripts/wad.gd")
const NAMESPACE := "Wolf3D";

# This will be the name of the header lump [1] when the map is exported. It also gets used as the
# basename of the WAD file.
#
# [1]: <https://github.com/rheit/zdoom/blob/d44976175256f3db8ec61cca40f1267cca68967d/specs/udmf.txt#L161>
export var internal_name := "MAP01"
export var automap_name : String = internal_name


static func property_assignment_statement(property: String, value) -> String:
	return '%s=%s;' % [property, var2str(value)]


func convert_to_uwmf() -> String:
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
	return \
		property_assignment_statement("NAMESPACE", NAMESPACE) \
		+ property_assignment_statement("NAME", automap_name)


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
