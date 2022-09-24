extends Node

const Wad := preload("res://wolf_editing_tools/scenes_and_scripts/wad.gd")

# This will be the name of the header lump [1] when the map is exported.
#
# [1]: <https://github.com/rheit/zdoom/blob/d44976175256f3db8ec61cca40f1267cca68967d/specs/udmf.txt#L161>
export var internal_name := "MAP01"


# For the moment, I’m going to make _ready() export the map.
func _ready() -> void:
	var name : = "01234567"
	var contents := PoolByteArray()
	
	var lump := Wad.Lump.new(name, contents)
	var wad := Wad.new()
	assert(wad.append_lump(lump), "Appending lump failed.")
	assert(wad.save("user://TEST.WAD") == OK, "Saving WAD failed.")
