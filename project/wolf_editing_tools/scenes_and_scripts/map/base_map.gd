extends Node

const Tile := preload("res://wolf_editing_tools/scenes_and_scripts/map/tile.gd")
const Wad := preload("res://wolf_editing_tools/scenes_and_scripts/file_formats/wad.gd")
const NAMESPACE := "Wolf3D";
const REQUIRED_COMPONENTS := ["tile", "sector", "zone"]

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
	var return_value := name.to_upper() + "{"
	for key in contents:
		# Take a look at the comment in convert_to_uwmf for why I’m doing it
		# like this.
		return_value += property_assignment_statement(key.to_upper(), contents[key])
	return_value += "}"
	return return_value


func size() -> Vector3:
	var return_value := Vector3.ZERO
	for child in get_children():
		if child is MapObject:
			var max_coordinates : Vector3 = child.max_uwmf_x_y_z()
			return_value.x = max(return_value.x, max_coordinates.x)
			return_value.y = max(return_value.y, max_coordinates.y)
			return_value.z = max(return_value.z, max_coordinates.z)
	return return_value


func convert_to_uwmf() -> String:
	var size := size()
	var return_value := (
		property_assignment_statement("namespace", NAMESPACE)
		+ property_assignment_statement("name", automap_name)
		+ property_assignment_statement("tileSize", tile_size)
		+ property_assignment_statement("width", int(size.x))
		+ property_assignment_statement("height", int(size.y))
		# TODO: This shouldn’t be hard codded.
		+ named_block("plane", { "depth" : 64 })
	)
	
	# TODO: Allow for more than one plane map.
	var plane_map := []
	# warning-ignore:narrowing_conversion
	plane_map.resize(size.y)
	for row in len(plane_map):
		plane_map[row] = []
		plane_map[row].resize(size.x)
	
	# First, populate the plane_map…
	var next_tile_index := 0
	var tile_to_index := {}
	# TODO: Make this search recursive.
	for child in get_children():
		if child is Tile:
			var uwmf_block : String = child.to_uwmf()
			if not uwmf_block in tile_to_index:
				return_value += uwmf_block
				tile_to_index[uwmf_block] = next_tile_index
				next_tile_index += 1
			var position : Vector3 = child.uwmf_position()
			if plane_map[position.y][position.x] == null:
				plane_map[position.y][position.x] = {}
			plane_map[position.y][position.x]["tile"] = tile_to_index[uwmf_block]
	# …then, convert the plane_map to the UWMF.
	return_value += "PLANEMAP{"
	for row in len(plane_map):
		for column in len(plane_map[row]):
			var item = plane_map[row][column]
			if item == null:
				item = {}
			
			return_value += "{"
			for i in len(REQUIRED_COMPONENTS):
				return_value += var2str(item.get(REQUIRED_COMPONENTS[i], -1))
				if i != (len(REQUIRED_COMPONENTS) - 1):
					return_value += ","
			if "tag" in item:
				return_value += ","
				return_value += var2str(item["tag"])
			return_value += "}"
			if column != len(plane_map[row]) - 1:
				return_value += ","
		if row != len(plane_map) - 1:
			return_value += ","
	return_value += "}"
	return return_value


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
