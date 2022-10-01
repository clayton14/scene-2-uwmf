extends TextureRect


func _ready() -> void:
	var packed_scene := preload("res://wolf_editing_tools/scenes_and_scripts/test/scene_with_tiles.tscn")
	var scene := packed_scene.instance()
	var tile := scene.get_node("Tile")
	if tile is Tile:
		var material : Material = tile.get_surface_material(0)
		if material is SpatialMaterial:
			texture = material.albedo_texture
		else:
			push_error("material was the wrong type.")
	else:
		push_error("tile was the wrong type.")
	scene.queue_free()
