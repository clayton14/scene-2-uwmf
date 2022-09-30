extends Node


onready var tile := $Tile
onready var texture_rect := $TextureRect


func _physics_process(delta: float) -> void:
	texture_rect.texture = tile.mesh.surface_get_material(0).albedo_texture
	tile.rotate(Vector3.UP, PI / 8 * delta)
