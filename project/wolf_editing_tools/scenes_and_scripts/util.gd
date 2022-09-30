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


static func make_dir_recursive_or_error(to_create : String) -> void:
	if Directory.new().make_dir_recursive(to_create) != OK:
		push_error("Failed to create directory “%s”" % [to_create])


static func texture_path(dir_path : String, basename : String) -> String:
	dir_path = add_missing_trailing_slash(dir_path)
	# This is just a guess to fallback on if the file doesn’t exist.
	var return_value := dir_path + basename + ".tex"
	var dir := Directory.new()
	var error_code : int = dir.open(dir_path)
	if error_code == OK:
		error_code = dir.list_dir_begin(true)
		if error_code == OK:
			var current_name := dir.get_next()
			while current_name != "":
				if current_name.get_file().get_basename() == basename:
					return_value = dir_path + current_name
					break
				current_name = dir.get_next()
		else:
			failed_to_ls(dir, error_code)
	else:
		unhandled_error_while_opening_dir(error_code)
	return return_value


static func missing_texture_path() -> String:
	return texture_path("res://wolf_editing_tools/generated/art/", "missing_texture")


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


static func save_texture(
		texture : Resource,
		output_dir : String,
		base_filename : String
) -> String:
	output_dir = add_missing_trailing_slash(output_dir)
	var recognized_extensions : Array = ResourceSaver.get_recognized_extensions(texture)
	var file_extension : String
	if "tex" in recognized_extensions:
		file_extension = "tex"
	else:
		file_extension = recognized_extensions[0]
	var full_path : String = output_dir + base_filename + "." + file_extension
	if ResourceSaver.save(full_path, texture) != OK:
		push_error("Failed to save “%s”" % [full_path])
	return full_path


func _init() -> void:
	push_warning("Util is a utillity class. Why are you constructing it?")
