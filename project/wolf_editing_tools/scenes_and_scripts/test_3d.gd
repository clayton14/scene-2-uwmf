extends Node


onready var tile := $Tile


func _ready() -> void:
	$TextureRect.texture = tile.get_surface_material(0).albedo_texture
	print(tile.get_surface_material(0))

func _physics_process(delta: float) -> void:
	tile.rotate(Vector3.UP, PI / 8 * delta)
