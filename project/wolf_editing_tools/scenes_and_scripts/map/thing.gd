tool
extends MapObject


const BaseMap := preload("res://wolf_editing_tools/scenes_and_scripts/map/base_map.gd")
const LATEST_DEFAULT_TYPE := -1


# The UWMF spec says that type should be a string, but the latest stable version
# of ECWolf requires that ints are used. I took a look at ECWolf’s master
# branch, and it looks like using ints for thing types is still supported, but
# deprecated.
export var type := LATEST_DEFAULT_TYPE setget set_type
export var skill1 := true
export var skill2 := true
export var skill3 := true
export var skill4 := true
var _default_type := LATEST_DEFAULT_TYPE
var _initialized_type := false


func _enter_tree() -> void:
	var ancestor := get_parent()
	while ancestor != null and not ancestor is BaseMap:
		ancestor = ancestor.get_parent()

	if ancestor == null:
		_initialize_defaults(BaseMap.LATEST_API_VERSION)
	else:
		var error_code := ancestor.connect(
			"api_version_initialized",
			self,
			"_initialize_defaults",
			[],
			CONNECT_ONESHOT
		)
		if error_code != OK:
			push_error(
				"Failed to connect BaseMap.api_version_initialized to "
				+ "Thing._initialize_defaults with error code %s. Using "
				+ "defaults for latest api_version…"
				% [error_code]
			)
			_initialize_defaults(BaseMap.LATEST_API_VERSION)


func _initialize_defaults(api_version : int) -> void:
	if api_version < 0:
		push_error(
			"Invalid api_version %s. Using 0 as the api_version."
			% [api_version]
		)
		api_version = 0

	if api_version == 0:
		_default_type = 1
	else:
		_default_type = -1

	if not _initialized_type:
		type = _default_type


func set_type(new_type : int) -> void:
	type = new_type
	_initialized_type = true


func to_uwmf() -> String:
	var position := uwmf_position()
	var contents := {
		"type" : type,
		"x" : position.x,
		"y" : position.y,
		"z" : position.z
	}
	# According to the UWMF spec, if a skill property is missing, it defaults to
	# false [1]. Not storing a value takes up less space, so we only store a
	# skill property if it’s true.
	#
	# [1]: <https://maniacsvault.net/ecwolf/wiki/Universal_Wolfenstein_Map_Format#Optional_Properties_5>
	if skill1:
		contents["skill1"] = true
	if skill2:
		contents["skill2"] = true
	if skill3:
		contents["skill3"] = true
	if skill4:
		contents["skill4"] = true
	return Util.named_block("thing", contents)


func property_can_revert(name) -> bool:
	if name is String and name == "type" and type != _default_type:
		return true
	else:
		return false


func property_get_revert(name):
	if name is String and name == "type":
		return _default_type
	return null
