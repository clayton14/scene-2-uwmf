tool
extends Spatial


const EAST_FACE_PATH := @"EastFace"
const OVERHEAD_FACE_PATH := @"OverheadFace"

export var texture_east : Texture setget set_texture_east
export var texture_north : Texture setget set_texture_north
export var texture_south : Texture setget set_texture_south
export var texture_west : Texture setget set_texture_west
export var texture_overhead : Texture setget set_texture_overhead


func get_mesh_instance(path : NodePath): #-> MeshInstance:  # Doesn’t work.
	var return_value := get_node(path)
	if return_value is MeshInstance:
		return return_value
	else:
		push_error("“%s” wasn’t a MeshInstance." % [path])
		return null


func set_texture(path : NodePath, new_texture : Texture) -> void:
	var face = get_mesh_instance(path)
	if face != null:
		if new_texture == null:
			face.material_override = null
		else:
			var new_material := SpatialMaterial.new()
			new_material.flags_unshaded = true
			new_material.albedo_texture = new_texture
			face.material_override = new_material


func set_texture_east(new_texture_east : Texture) -> void:
	set_texture(EAST_FACE_PATH, new_texture_east)
	texture_east = new_texture_east


func set_texture_north(new_texture_north : Texture) -> void:
	set_texture(@"NorthFace", new_texture_north)
	texture_north = new_texture_north


func set_texture_south(new_texture_south : Texture) -> void:
	set_texture(@"SouthFace", new_texture_south)
	texture_south = new_texture_south


func set_texture_west(new_texture_west : Texture) -> void:
	set_texture(@"WestFace", new_texture_west)
	texture_west = new_texture_west


func set_texture_overhead(new_texture_overhead : Texture) -> void:
	if new_texture_overhead == null:
		var overhead_face = get_mesh_instance(OVERHEAD_FACE_PATH)
		var east_face = get_mesh_instance(EAST_FACE_PATH)
		if overhead_face != null and east_face != null:
			overhead_face.material_override = east_face.material_override
	else:
		set_texture(OVERHEAD_FACE_PATH, new_texture_overhead)
	texture_overhead = new_texture_overhead
