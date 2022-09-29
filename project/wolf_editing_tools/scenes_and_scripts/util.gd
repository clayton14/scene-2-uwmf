extends Object


static func add_missing_trailing_slash(path_to_dir : String) -> String:
	if path_to_dir.ends_with("/"):
		return path_to_dir
	else:
		return path_to_dir + "/"


static func make_dir_recursive_or_error(to_create : String) -> void:
	if Directory.new().make_dir_recursive(to_create) != OK:
		push_error("Failed to create directory “%s”" % [to_create])


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
			push_error("Failed to list contents of directory “%s”" % [to_remove])
	elif error_code != ERR_INVALID_PARAMETER:
		# ERR_INVALID_PARAMETER is returned when the directory doesn’t exist.
		# Since we’re trying to get rid of the directory, ERR_INVALID_PARAMETER
		# is fine.
		push_error("Unhandled error while opening directory: %s" % [error_code])


static func save_texture(
		texture : Resource,
		output_dir : String,
		base_filename : String
) -> void:
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


func _init() -> void:
	push_warning("Util is a utillity class. Why are you constructing it?")
