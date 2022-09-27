tool
extends Spatial


const Wall := preload("res://wolf_editing_tools/scenes_and_scripts/map/wall.gd")

export var texture_east : Texture = Wall.DEFAULT_TEXTURE setget set_texture_east, get_texture_east
export var texture_north : Texture = Wall.DEFAULT_TEXTURE setget set_texture_north, get_texture_north
export var texture_south : Texture = Wall.DEFAULT_TEXTURE setget set_texture_south, get_texture_south
export var texture_west : Texture = Wall.DEFAULT_TEXTURE setget set_texture_west, get_texture_west


func set_texture_east(new_texture_east : Texture) -> void:
	$East.texture = new_texture_east

func get_texture_east() -> Texture:
	return $East.texture

func set_texture_north(new_texture_north : Texture) -> void:
	$North.texture = new_texture_north

func get_texture_north() -> Texture:
	return $North.texture

func set_texture_south(new_texture_south : Texture) -> void:
	$South.texture = new_texture_south

func get_texture_south() -> Texture:
	return $South.texture

func set_texture_west(new_texture_west : Texture) -> void:
	$West.texture = new_texture_west

func get_texture_west() -> Texture:
	return $West.texture
