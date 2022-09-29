tool
extends MeshInstance


const VSwap := preload("res://wolf_editing_tools/scenes_and_scripts/file_formats/v_swap.gd")
const MISSING_TEXTURE_PATH := "res://wolf_editing_tools/generated/art/missing_texture.tex"
const IMAGE_FORMAT := Image.FORMAT_RGB8

export(String, FILE, "*.tex") var texture_east_path : String = MISSING_TEXTURE_PATH setget set_texture_east_path
export(String, FILE, "*.tex") var texture_north_path : String = MISSING_TEXTURE_PATH setget set_texture_north_path
export(String, FILE, "*.tex") var texture_south_path : String = MISSING_TEXTURE_PATH setget set_texture_south_path
export(String, FILE, "*.tex") var texture_west_path : String = MISSING_TEXTURE_PATH setget set_texture_west_path


func effective_automap_texture_path() -> String:
	return texture_east_path

func _update_material() -> void:
	var albedo_image := Image.new()
	# TODO: What are mipmaps? Should use_mipmaps be true?
	albedo_image.create(VSwap.WALL_LENGTH * 3, VSwap.WALL_LENGTH * 2, false, IMAGE_FORMAT)
	var face_texture_paths := [
			texture_north_path,
			texture_east_path,
			texture_south_path,
			texture_west_path,
			effective_automap_texture_path(),
			effective_automap_texture_path()
	]
	for face_number in 6:
		var texture_to_add = load(face_texture_paths[face_number])
		var image_to_add : Image
		if texture_to_add == null:
			push_error("Failed to load “%s”. Using “%s” as a fallback…" % [face_texture_paths[face_number], MISSING_TEXTURE_PATH])
			texture_to_add = load(MISSING_TEXTURE_PATH)
			if texture_to_add == null:
				push_error("Failed to load fallback texture. Using a completely black square as a fallback…")
				image_to_add = Image.new()
				image_to_add.create(VSwap.WALL_LENGTH, VSwap.WALL_LENGTH, false, Image.FORMAT_L8)
				image_to_add.fill(Color.black)
		if image_to_add == null:
			image_to_add = texture_to_add.get_data()
		
		var row : int = face_number % 3
		var column : int = 0 if face_number < 3 else 1
		image_to_add.resize(VSwap.WALL_LENGTH, VSwap.WALL_LENGTH, Image.INTERPOLATE_NEAREST)
		if face_number == 4:
			# Without this, the top texture would appear upside down.
			image_to_add.unlock()
			image_to_add.flip_x()
			image_to_add.flip_y()
			image_to_add.lock()
		albedo_image.blit_rect(
				image_to_add,
				Rect2(0, 0, VSwap.WALL_LENGTH, VSwap.WALL_LENGTH),
				Vector2(row * VSwap.WALL_LENGTH, column * VSwap.WALL_LENGTH)
		)
	var albedo_texture := ImageTexture.new()
	albedo_texture.create_from_image(albedo_image, Texture.FLAGS_DEFAULT & ~Texture.FLAG_FILTER)
	
	var new_material := SpatialMaterial.new()
	new_material.flags_unshaded = true
	new_material.albedo_texture = albedo_texture
	mesh.surface_set_material(0, new_material)


func _ready() -> void:
	_update_material()


func set_texture_east_path(new_texture_path : String) -> void:
	texture_east_path = new_texture_path
	_update_material()


func set_texture_north_path(new_texture_path : String) -> void:
	texture_north_path = new_texture_path
	_update_material()


func set_texture_south_path(new_texture_path : String) -> void:
	texture_south_path = new_texture_path
	_update_material()


func set_texture_west_path(new_texture_path : String) -> void:
	texture_west_path = new_texture_path
	_update_material()
