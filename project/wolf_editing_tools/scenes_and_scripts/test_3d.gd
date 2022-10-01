extends Node


onready var tile : Tile = $Tile
onready var texture_rect := $TextureRect


func _physics_process(delta: float) -> void:
	var tile_material = tile.get_surface_material(0)
	if tile_material is SpatialMaterial:
		texture_rect.texture = tile_material.albedo_texture
	tile.rotate(Vector3.UP, PI / 8 * delta)
