extends Node


onready var tile := $Tile


func _physics_process(delta: float) -> void:
	tile.rotate(Vector3.UP, PI / 8 * delta)
