extends ColorRect


const Pk3 := preload("res://wolf_editing_tools/scenes_and_scripts/file_formats/pk3.gd")
const VSwap := preload("res://wolf_editing_tools/scenes_and_scripts/file_formats/v_swap.gd")
const OUTPUT_DIR := "res://wolf_editing_tools/generated/"

var thread := Thread.new()
var ecwolf_pk3_path : String setget set_ecwolf_pk3_path
var v_swap_path : String setget set_v_swap_path
var prompting_for_ecwolf_pk3 := true

onready var file_dialog : FileDialog = $FileDialog
onready var ecwolf_pk3_input_field : LineEdit = $MainScreen/VBoxContainer/GridContainer/EcwolfPk3PathInputField
onready var v_swap_input_field : LineEdit = $MainScreen/VBoxContainer/GridContainer/VSwapPathInputField
onready var loading_screen : Control = $LoadingScreen


static func add_missing_trailing_slash(path_to_dir : String) -> String:
	if path_to_dir.ends_with("/"):
		return path_to_dir
	else:
		return path_to_dir + "/"

static func recursively_create_directory(to_create : String) -> void:
	if Directory.new().make_dir_recursive(to_create) != OK:
		push_error("Failed to create directory “%s”" % [to_create])


static func recursively_remove_directory(to_remove : String) -> void:
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
					recursively_remove_directory(current_full_path)
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


static func save_texture(texture : Resource, output_dir : String, base_filename : String) -> void:
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


func set_ecwolf_pk3_path(new_ecwolf_pk3_path : String) -> void:
	ecwolf_pk3_input_field.text = new_ecwolf_pk3_path
	ecwolf_pk3_path = new_ecwolf_pk3_path


func set_v_swap_path(new_v_swap_path : String) -> void:
	v_swap_input_field.text = new_v_swap_path
	v_swap_path = new_v_swap_path


func prompt_for_file() -> void:
	var window_title : String
	var filters : PoolStringArray
	if prompting_for_ecwolf_pk3:
		window_title = "Open ecwolf.pk3"
		filters = PoolStringArray(["ecwolf.pk3"])
	else:
		window_title = "Open VSWAP.*"
		filters = PoolStringArray(["VSWAP.* ; VSWAP"])
	
	var popup_size : Vector2 = get_viewport().get_visible_rect().size
	popup_size *= 0.75
	file_dialog.window_title = window_title
	file_dialog.filters = filters
	file_dialog.popup_centered(popup_size)


func _on_FileDialog_file_selected(path : String) -> void:
	if prompting_for_ecwolf_pk3:
		set_ecwolf_pk3_path(path)
	else:
		set_v_swap_path(path)


func _on_EcwolfPk3PathBrowseButton_pressed() -> void:
	prompting_for_ecwolf_pk3 = true
	prompt_for_file()


func _on_VSwapPathBrowseButton_pressed():
	prompting_for_ecwolf_pk3 = false
	prompt_for_file()


func _on_EcwolfPk3PathInputField_text_changed(new_text : String) -> void:
	ecwolf_pk3_path = new_text


func _on_VSwapPathInputField_text_changed(new_text : String) -> void:
	v_swap_path = new_text


func generate_assets() -> void:
	var ecwolf_pk3 := Pk3.new(ecwolf_pk3_path)
	var v_swap := VSwap.new(ecwolf_pk3, v_swap_path)
	var finished_screen : Label = $FinishedScreen
	# TODO: Find a better way to detect errors.
	if ecwolf_pk3.archive_path != ecwolf_pk3_path or v_swap.v_swap_path != v_swap_path:
		color = Color("930000")
		finished_screen.text = """Tried generating assets, but it looks like there were errors.
Check the debugger for details."""
	else:
		save_texture(ecwolf_pk3.missing_texture, OUTPUT_DIR, "missing_texture")
		
		var walls_dir : String = OUTPUT_DIR + "art/walls/" + v_swap_path.get_file() + "/"
		recursively_remove_directory(walls_dir)
		recursively_create_directory(walls_dir)
		for wall_name in v_swap.walls:
			save_texture(v_swap.walls[wall_name], walls_dir, wall_name)
		
		color = Color("439300")
		finished_screen.text = """Finished generating assets.
Please check the debugger for any errors."""
	finished_screen.text += "\n(You can close out of this window now)"
	
	loading_screen.hide()
	finished_screen.show()


func _on_GenerateAssets_pressed() -> void:
	loading_screen.show()
	$MainScreen.hide()
	if thread.start(self, "generate_assets") != OK:
		push_warning("Failed to start separate Thread for generating assets. Generating assets on the main thread…")
		generate_assets()


func _exit_tree() -> void:
	if thread != null and thread.is_active():
		thread.wait_to_finish()
