tool
extends MeshInstance


const DEFAULT_TEXTURE := preload("res://wolf_editing_tools/generated/missing_texture.tex")
export var texture : Texture = DEFAULT_TEXTURE setget set_texture


func set_texture(new_texture : Texture) -> void:
	texture = new_texture
	var material := SpatialMaterial.new()
	material.flags_unshaded = true
	material.albedo_texture = new_texture
	set_surface_material(0, material)


func _ready() -> void:
	set_texture(texture)
