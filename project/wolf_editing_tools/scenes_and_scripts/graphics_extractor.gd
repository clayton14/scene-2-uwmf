extends ColorRect


const OUTPUT_DIR := "res://wolf_editing_tools/generated/"

var thread := Thread.new()
var ecwolf_pk3_path : String setget set_ecwolf_pk3_path
var v_swap_path : String setget set_v_swap_path
var prompting_for_ecwolf_pk3 := true

onready var file_dialog : FileDialog = $FileDialog
onready var ecwolf_pk3_input_field : LineEdit = $MainScreen/VBoxContainer/GridContainer/EcwolfPk3PathInputField
onready var v_swap_input_field : LineEdit = $MainScreen/VBoxContainer/GridContainer/VSwapPathInputField
onready var loading_screen : Control = $LoadingScreen


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


func extract_assets() -> void:
	var ecwolf_pk3 := Pk3.new(ecwolf_pk3_path)
	var v_swap := VSwap.new(ecwolf_pk3, v_swap_path)
	var finished_screen : Label = $FinishedScreen
	# TODO: Find a better way to detect errors.
	if ecwolf_pk3.archive_path != ecwolf_pk3_path or v_swap.v_swap_path != v_swap_path:
		color = Color("930000")
		finished_screen.text = """Tried extracting graphics, but it looks like there were errors.
Check the debugger for details."""
	else:
		var art_dir := OUTPUT_DIR + "art/"
		Util.make_dir_recursive_or_error(art_dir)
		Util.save_texture(ecwolf_pk3.missing_texture, art_dir, "missing_texture")

		var walls_dir : String = art_dir + "walls/" + v_swap_path.get_file() + "/"
		Util.remove_dir_recursive_or_error(walls_dir)
		Util.make_dir_recursive_or_error(walls_dir)
		for wall_name in v_swap.walls:
			Util.save_texture(v_swap.walls[wall_name], walls_dir, wall_name)

		color = Color("439300")
		finished_screen.text = """Finished extracting graphics.
Please check the debugger for any errors."""
	finished_screen.text += "\n(You can close out of this window now)"

	loading_screen.hide()
	finished_screen.show()


func _on_ExtractGraphics_pressed() -> void:
	loading_screen.show()
	$MainScreen.hide()
	if thread.start(self, "extract_assets") != OK:
		push_warning("Failed to start separate Thread for generating assets. Generating assets on the main thread…")
		extract_assets()


func _exit_tree() -> void:
	if thread != null and thread.is_active():
		thread.wait_to_finish()
