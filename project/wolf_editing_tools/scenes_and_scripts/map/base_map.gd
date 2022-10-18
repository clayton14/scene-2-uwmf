tool
extends Node

signal api_version_initialized(api_version)


const Sector = preload("res://wolf_editing_tools/scenes_and_scripts/map/sector.gd")
const Tile := preload("res://wolf_editing_tools/scenes_and_scripts/map/tile.gd")
const Wad := preload("res://wolf_editing_tools/scenes_and_scripts/file_formats/wad.gd")
const BASE_MAP_SCENE_PATH := "res://wolf_editing_tools/scenes_and_scripts/map/base_map.tscn"
const LATEST_API_VERSION := 1
const NAMESPACE := "Wolf3D";
const REQUIRED_COMPONENTS := ["tile", "sector", "zone"]
const TRIED_TO_SET_WRONG_TYPE := "Tried to set %s to something that isn’t a %s."


# This will be the name of the header lump [1] when the map is exported. It also gets used as the
# basename of the WAD file.
#
# [1]: <https://github.com/rheit/zdoom/blob/d44976175256f3db8ec61cca40f1267cca68967d/specs/udmf.txt#L161>
export var internal_name := "MAP01"
export var automap_name : String = internal_name
# Are there any ports that even support a different value?
export var tile_size := 64
# -1 isn’t a real api_version. -1 means “api_verison hasn’t been initialized
# yet.”
var api_version := -1
var default_sector_enabled := true
var default_sector = Sector.new()
# If this is true, then this script is attached to the scene located at
# BASE_MAP_SCENE_PATH. If this is false, then this script is almost certainly
# attached to either an instance of the BaseMap scene or a scene which inherits
# from the BaseMap scene.
var _attached_to_base_map_scene : bool


func _enter_tree() -> void:
	_attached_to_base_map_scene = filename == BASE_MAP_SCENE_PATH


func size() -> Vector3:
	var return_value := Vector3.ZERO
	for child in get_children():
		if child is MapObject:
			var max_coordinates : Vector3 = child.max_uwmf_x_y_z()
			return_value.x = max(return_value.x, max_coordinates.x)
			return_value.y = max(return_value.y, max_coordinates.y)
			return_value.z = max(return_value.z, max_coordinates.z)
	return return_value


func component_default(component : String):
	if component == "sector" and default_sector_enabled:
		return 0
	else:
		return -1


func to_uwmf() -> String:
	var size := size()
	var return_value := (
		Util.property_assignment_statement("namespace", NAMESPACE)
		+ Util.property_assignment_statement("name", automap_name)
		+ Util.property_assignment_statement("tileSize", tile_size)
		+ Util.property_assignment_statement("width", int(size.x))
		+ Util.property_assignment_statement("height", int(size.y))
		# TODO: This shouldn’t be hard codded.
		+ Util.named_block("plane", [{ "depth" : 64 }])
	)

	if default_sector_enabled:
		return_value += default_sector.to_uwmf()

	# TODO: Allow for more than one plane map.
	var plane_map := []
	# warning-ignore:narrowing_conversion
	plane_map.resize(size.y)
	for row in len(plane_map):
		plane_map[row] = []
		plane_map[row].resize(size.x)

	# First, convert everything that doesn’t belong in the plane map to UWMF and
	# populate the plane_map…
	var next_tile_index := 0
	var tile_to_index := {}
	# TODO: Make this search recursive.
	for child in get_children():
		if child is MapObject:
			var uwmf_block : String = child.to_uwmf()
			if child is Tile:
				if not uwmf_block in tile_to_index:
					return_value += uwmf_block
					tile_to_index[uwmf_block] = next_tile_index
					next_tile_index += 1
				var position : Vector3 = child.uwmf_position()
				if plane_map[position.y][position.x] == null:
					plane_map[position.y][position.x] = {}
				plane_map[position.y][position.x]["tile"] = tile_to_index[uwmf_block]
			else:
				return_value += uwmf_block
	# …then, convert the plane_map to UWMF.
	return_value += "PLANEMAP{"
	for row in len(plane_map):
		for column in len(plane_map[row]):
			var item = plane_map[row][column]
			if item == null:
				item = {}

			return_value += "{"
			for i in len(REQUIRED_COMPONENTS):
				return_value += var2str(item.get(
					REQUIRED_COMPONENTS[i],
					component_default(REQUIRED_COMPONENTS[i])
				))
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


func _ready() -> void:
	# At this point, Godot will have set all of the properties saved in the
	# current scene’s file. If api_version is still -1, then we’re in one of
	# these three situations:
		#
		# 1. _attached_to_base_map_scene is true,
		# 2. this script is attached to a brand new level or
		# 3. the current scene is an old level that doesn’t have an api_version
		# becauase it was last edited before api_version was added.
		#
	# We can ignore situation 1. The BaseMap scene’s api_level doesn’t really
	# matter because users shouldn’t use the BaseMap scene directly (they should
	# inherit from it).
	#
	# Unfortunately, it’s impossible to truly differentiate between situations
	# 2 and 3. The best I’ve come up with is the following:
		#
		# • If this Node has children, then assume that we’re in situation 3.
		# • If this Node does not have children, then assume that we’re in
		# situation 2.
		#
	# Those assumptions aren’t perfect. A user could have created an old level
	# that just so happended to be empty. That being said, I can’t think of any
	# consequences for incorrectly updating an empty level’s api_verison.
	if api_version == -1:
		if get_child_count() == 0:
			api_version = LATEST_API_VERSION
		else:
			api_version = 0
	emit_signal("api_version_initialized", api_version)

	# For the moment, I’m going to make _ready() export the map.
	if !Engine.editor_hint:
		var wad := Wad.new()
		var lumps := [
			Wad.Lump.new(internal_name, PoolByteArray()),
			Wad.Lump.new("TEXTMAP", to_uwmf().to_utf8()),
			Wad.Lump.new("ENDMAP", PoolByteArray()),
		]
		assert(wad.set_lumps(lumps), "Setting lumps failed.")
		assert(wad.save("user://%s.WAD" % [internal_name]) == OK, "Saving WAD failed.")


static func _texture_property(name : String) -> Dictionary:
	return {
		"name" : name,
		"type" : TYPE_OBJECT,
		"hint" : PROPERTY_HINT_RESOURCE_TYPE,
		"hint_string" : "Texture"
	}


static func is_valid_texture_value(property_name : String, value) -> bool:
	if value == null or value is Texture:
		return true
	else:
		push_error(TRIED_TO_SET_WRONG_TYPE % [property_name, "Texture"])
		return false


static func are_textures_equal(texture1 : Texture, texture2 : Texture) -> bool:
	if texture1 is SingleColorTexture and texture2 is SingleColorTexture:
		return (
			texture1.color.r8 == texture2.color.r8
			and texture1.color.g8 == texture2.color.g8
			and texture1.color.b8 == texture2.color.b8
			and texture1.color.a8 == texture2.color.a8
		)
	elif texture1.resource_path != "" and texture2.resource_path != "":
		return texture1.resource_path == texture2.resource_path
	else:
		return texture1 == texture2


func _get_property_list() -> Array:
	var return_value := [
		{
			"name" : "default_sector/enabled",
			"type" : TYPE_BOOL
		},
		_texture_property("default_sector/texture_ceiling"),
		_texture_property("default_sector/texture_floor")
	]

	# api_version shouldn’t be stored in the BaseMap scene. It should only be
	# stored in scenes that instantiate the BaseMap scene or inherit from the
	# BaseMap scene. Doing so ensures that updating Scene 2 UWMF doesn’t
	# inadvertently increase a map’s api_version.
	if not _attached_to_base_map_scene:
		return_value.append({
			"name" : "api_version",
			"type" : typeof(api_version),
			"usage" : PROPERTY_USAGE_NOEDITOR
		})

	return return_value


func _get(property):
	match property:
		"api_version":
			if not _attached_to_base_map_scene:
				return api_version
		"default_sector/enabled":
			return default_sector_enabled
		"default_sector/texture_ceiling":
			return default_sector.texture_ceiling
		"default_sector/texture_floor":
			return default_sector.texture_floor
	return null


func _set(property, value) -> bool:
	match property:
		"api_version":
			if not _attached_to_base_map_scene and value is int:
				api_version = value
				return true
		"default_sector/enabled":
			if value is bool:
				default_sector_enabled = value
				return true
			else:
				push_error(TRIED_TO_SET_WRONG_TYPE % [property, "bool"])
		"default_sector/texture_ceiling":
			if is_valid_texture_value("default_sector/texture_ceiling", value):
				default_sector.texture_ceiling = value
				return true
		"default_sector/texture_floor":
			if is_valid_texture_value("default_sector/texture_floor", value):
				default_sector.texture_floor = value
				return true
	return false


func property_can_revert(name) -> bool:
	match name:
		"default_sector/enabled":
			return !default_sector_enabled
		"default_sector/texture_ceiling":
			return !are_textures_equal(
				default_sector.texture_ceiling,
				Sector.default_texture_ceiling()
			)
		"default_sector/texture_floor":
			return !are_textures_equal(
				default_sector.texture_floor,
				Sector.default_texture_floor()
			)
	return false


func property_get_revert(name):
	match name:
		"default_sector/enabled":
			return true
		"default_sector/texture_ceiling":
			return Sector.default_texture_ceiling()
		"default_sector/texture_floor":
			return Sector.default_texture_floor()
	return null
