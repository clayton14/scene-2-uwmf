tool
extends Spatial


export var texture_east : Texture setget set_texture_east


func set_texture_east(new_texture_east : Texture) -> void:
	var wall_east := $WallEast
	if wall_east is MeshInstance:
		if new_texture_east == null:
			wall_east.material_override = null
		else:
			var new_material := SpatialMaterial.new()
			new_material.flags_unshaded = true
			new_material.albedo_texture = new_texture_east
			wall_east.material_override = new_material
	else:
		push_error("wall_east wasn’t a MeshInstance.")
	texture_east = new_texture_east
