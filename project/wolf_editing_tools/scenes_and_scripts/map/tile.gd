tool
extends Spatial


export var texture_east : Texture setget set_texture_east
export var texture_north : Texture setget set_texture_north
export var texture_south : Texture setget set_texture_south


func set_texture(wall : Node, new_texture : Texture) -> void:
	if wall is MeshInstance:
		if new_texture == null:
			wall.material_override = null
		else:
			var new_material := SpatialMaterial.new()
			new_material.flags_unshaded = true
			new_material.albedo_texture = new_texture
			wall.material_override = new_material
	else:
		push_error("wall_east wasn’t a MeshInstance.")


func set_texture_east(new_texture_east : Texture) -> void:
	set_texture($WallEast, new_texture_east)
	texture_east = new_texture_east


func set_texture_north(new_texture_north : Texture) -> void:
	set_texture($WallNorth, new_texture_north)
	texture_north = new_texture_north


func set_texture_south(new_texture_south : Texture) -> void:
	set_texture($WallSouth, new_texture_south)
	texture_south = new_texture_south
