tool
extends MeshInstance


const AssetGenerator := preload("res://wolf_editing_tools/scenes_and_scripts/asset_generator.gd")
const VSwap := preload("res://wolf_editing_tools/scenes_and_scripts/file_formats/v_swap.gd")
# TODO: There’s a chance that this won’t end in .tex. See asset_generator.gd’s save_texture() function.
const MISSING_TEXTURE_PATH := "res://wolf_editing_tools/generated/art/missing_texture.tex"
const IMAGE_FORMAT := Image.FORMAT_RGB8
const MATERIAL_DIR := "user://art/walls"

export(String, FILE, "*.tex") var texture_east_path : String = MISSING_TEXTURE_PATH setget set_texture_east_path
export(String, FILE, "*.tex") var texture_north_path : String = MISSING_TEXTURE_PATH setget set_texture_north_path
export(String, FILE, "*.tex") var texture_south_path : String = MISSING_TEXTURE_PATH setget set_texture_south_path
export(String, FILE, "*.tex") var texture_west_path : String = MISSING_TEXTURE_PATH setget set_texture_west_path


func face_texture_paths_hash(face_texture_paths : Array) -> int:
	var file_content_hashes := []
	file_content_hashes.resize(len(face_texture_paths))
	var file := File.new()
	for i in len(face_texture_paths):
		var sha256 := file.get_sha256(face_texture_paths[i])
		if sha256.empty():
			push_warning("Failed to open “%s”. Hashing path instead of file contents…" % [face_texture_paths[i]])
			file_content_hashes[i] = hash(face_texture_paths[i])
		else:
			file_content_hashes[i] = sha256
	return hash(file_content_hashes)


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
	var material_path = "%s/%x.res" % [MATERIAL_DIR, face_texture_paths_hash(face_texture_paths)]
	var material = load(material_path)
	if material == null:
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
		
		material = SpatialMaterial.new()
		material.flags_unshaded = true
		material.albedo_texture = albedo_texture
		
		AssetGenerator.recursively_create_directory(MATERIAL_DIR)
		if ResourceSaver.save(material_path, material) != OK:
			push_error("Failed to save material “%s”" % [material])
		# This ensures that Godot uses an external resource rather than an embedded one. If an
		# embeded resource was used, then the albedo_image will be embedded into the scene file. The
		# albedo_image is likely to contain copyrighted textures from Wolfenstein 3D, and users are
		# unlikely to have a license for that content. Scene files are the source files for maps, so
		# it’s important that end users are able to redistribute them.
		material = load(material_path)
	set_surface_material(0, material)


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
