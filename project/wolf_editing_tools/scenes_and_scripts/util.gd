extends Object
class_name Util


static func unhandled_error_while_opening_dir(error_code) -> void:
	push_error("Unhandled error while opening directory: %s" % [error_code])


static func failed_to_ls(dir, error_code) -> void:
	push_error(
			"Failed to list contents of directory “%s”. Error code: %s"
			% [dir, error_code]
	)

static func add_missing_trailing_slash(path_to_dir : String) -> String:
	if path_to_dir.ends_with("/"):
		return path_to_dir
	else:
		return path_to_dir + "/"


static func remove_dir_recursive_or_error(to_remove : String) -> void:
	to_remove = add_missing_trailing_slash(to_remove)
	var dir := Directory.new()
	var error_code : int = dir.open(to_remove)
	if error_code == OK:
		error_code = dir.list_dir_begin(true)
		if error_code == OK:
			var current_name := dir.get_next()
			while current_name != "":
				var current_full_path := to_remove + current_name
				if dir.current_is_dir():
					remove_dir_recursive_or_error(current_full_path)
				error_code = dir.remove(current_full_path)
				if error_code != OK:
					push_error("Failed to remove “%s”" % [current_full_path])
				current_name = dir.get_next()
		else:
			failed_to_ls(to_remove, error_code)
	elif error_code != ERR_INVALID_PARAMETER:
		# ERR_INVALID_PARAMETER is returned when the directory doesn’t exist.
		# Since we’re trying to get rid of the directory, ERR_INVALID_PARAMETER
		# is fine.
		unhandled_error_while_opening_dir(error_code)


static func texture_to_uwmf(texture : Texture) -> String:
	var SingleColorTextureType = load("res://wolf_editing_tools/scenes_and_scripts/resource_types/single_color_texture.gd")
	if texture is SingleColorTextureType:
		return texture.to_uwmf()
	else:
		return "%s" % [texture.resource_path.get_basename().get_file()]


func _init() -> void:
	push_warning("Util is a utillity class. Why are you constructing it?")
