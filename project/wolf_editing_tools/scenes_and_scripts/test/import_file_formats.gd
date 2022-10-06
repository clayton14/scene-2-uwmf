tool
extends Node


export(String, FILE, GLOBAL, "ecwolf.pk3") var ecwolf_pk3_path : String
export(String, FILE, GLOBAL, "VSWAP.*") var v_swap_path : String

var pk3: Pk3
var v_swap : VSwap

onready var palette_selector : OptionButton = $PaletteTest/MarginContainer/VBoxContainer/PaletteSelector
onready var missing_palette_label : Label = $PaletteTest/MarginContainer/VBoxContainer/AspectRatioContainer/MissingPaletteLabel
onready var palette_grid_container : Node = $PaletteTest/MarginContainer/VBoxContainer/AspectRatioContainer/PaletteGridContainer
onready var wall_selector : OptionButton = $WallsTest/MarginContainer/VBoxContainer/WallSelector
onready var wall : TextureRect = $WallsTest/MarginContainer/VBoxContainer/Wall


func _on_PaletteSelector_item_selected(index: int) -> void:
	update_palette_test(palette_selector.get_item_text(index))


func update_palette_test(file_extension: String) -> void:
	while palette_grid_container.get_child_count() > 0:
		palette_grid_container.remove_child(palette_grid_container.get_child(0))

	var palette = pk3.palettes.get(file_extension)

	if palette == null:
		missing_palette_label.show()
	else:
		missing_palette_label.hide()
		for color in palette:
			var color_rect := ColorRect.new()
			color_rect.size_flags_horizontal |= ColorRect.SIZE_EXPAND
			color_rect.size_flags_vertical |= ColorRect.SIZE_EXPAND
			color_rect.color = color
			palette_grid_container.add_child(color_rect)


func _on_WallSelector_item_selected(index: int) -> void:
	update_texture_selector_test(wall_selector.get_item_text(index))


func update_texture_selector_test(texture_name: String) -> void:
	wall.texture = v_swap.walls[texture_name]


func _ready() -> void:
	# I don’t want this to be a tool script, but I have to make it a tool script to get global
	# filesystems exports to work.
	if not Engine.editor_hint:
		pk3 = Pk3.new(ecwolf_pk3_path)
		assert(pk3.archive_path == ecwolf_pk3_path)
		# data_maps
		var data_maps_test := File.new()
		assert(data_maps_test.open("user://data_maps_test.txt", File.WRITE) == OK)
		for key in pk3.data_maps:
			data_maps_test.store_line(key + ":")
			for subkey in pk3.data_maps[key]:
				data_maps_test.store_line("\t" + subkey + ":")
				for value in pk3.data_maps[key][subkey]:
					data_maps_test.store_line("\t\t" + value)
		data_maps_test.close()
		# palettes
		for file_extension in pk3.palettes:
			palette_selector.add_item(file_extension)
		update_palette_test(pk3.palettes.keys()[0])

		v_swap = VSwap.new(pk3, v_swap_path)
		assert(v_swap.v_swap_path == v_swap_path)
		var wall_names := v_swap.wall_names()
		for wall_name in wall_names:
			wall_selector.add_item(wall_name)
		update_texture_selector_test(wall_names[0])
