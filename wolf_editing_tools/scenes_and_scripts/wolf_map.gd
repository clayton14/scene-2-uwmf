extends Node

const Wad := preload("res://wolf_editing_tools/scenes_and_scripts/wad.gd")

# This will be the name of the header lump [1] when the map is exported. It also gets used as the
# basename of the WAD file.
#
# [1]: <https://github.com/rheit/zdoom/blob/d44976175256f3db8ec61cca40f1267cca68967d/specs/udmf.txt#L161>
export var internal_name := "MAP01"


# For the moment, I’m going to make _ready() export the map.
func _ready() -> void:
	var wad := Wad.new()
	assert(wad.append_lump(Wad.Lump.new(internal_name, PoolByteArray())), "Appending lump failed.")
	assert(wad.save("user://%s.WAD" % [internal_name]) == OK, "Saving WAD failed.")
