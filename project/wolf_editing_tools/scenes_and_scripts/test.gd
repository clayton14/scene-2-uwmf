tool
extends Node


const Pk3 := preload("res://wolf_editing_tools/scenes_and_scripts/pk3.gd")

export(String, FILE, GLOBAL, "ecwolf.pk3") var ecwolf_pk3_path : String


func _ready() -> void:
	# I don’t want this to be a tool script, but I have to make it a tool script to get global
	# filesystems exports to work.
	if not Engine.editor_hint:
		var pk3 := Pk3.new(ecwolf_pk3_path)
		assert(pk3.archive_path == ecwolf_pk3_path)
		
		var data_maps_test := File.new()
		assert(data_maps_test.open("user://data_maps_test.txt", File.WRITE) == OK)
		for key in pk3.data_maps:
			data_maps_test.store_line(key + ":")
			for subkey in pk3.data_maps[key]:
				data_maps_test.store_line("\t" + subkey + ":")
				for value in pk3.data_maps[key][subkey]:
					data_maps_test.store_line("\t\t" + value)
		data_maps_test.close()
