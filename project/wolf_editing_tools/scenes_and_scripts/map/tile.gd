tool
extends MeshInstance


# This class will generate an Image that will be used as a Texture. Saving the
# scene will not save the Image to disk because this class inherits from
# ProxyTexture.
class WallTexture extends ProxyTexture:
	const BLACK_SQUARE_FALLBACK_ERROR := "Failed to load fallback texture. Using a completely black square as a fallback…"
	const IMAGE_FORMAT := Image.FORMAT_RGB8
	const OUTPUT_DIR := "res://wolf_editing_tools/generated/art/walls/cache/"
	
	var missing_texture : Texture = load(Util.missing_texture_path())
	
	export var texture_east : Texture = missing_texture setget set_texture_east
	export var texture_north : Texture = missing_texture setget set_texture_north
	export var texture_south : Texture = missing_texture setget set_texture_south
	export var texture_west : Texture = missing_texture setget set_texture_west
	
	
	func _init() -> void:
		# This will prevent errors when running Util.texture_path().
		Util.make_dir_recursive_or_error(OUTPUT_DIR)
		_update()
	
	
	func effective_automap_texture_path() -> String:
		return texture_east.resource_path
	
	
	func set_texture_east(new_texture_east : Texture) -> void:
		texture_east = new_texture_east
		_update()
	
	
	func set_texture_north(new_texture_north : Texture) -> void:
		texture_north = new_texture_north
		_update()
	
	
	func set_texture_south(new_texture_south : Texture) -> void:
		texture_south = new_texture_south
		_update()
	
	
	func set_texture_west(new_texture_west : Texture) -> void:
		texture_west = new_texture_west
		_update()
	
	
	static func _backing_texture_id(face_texture_paths : Array) -> String:
		var face_texture_hashes := []
		face_texture_hashes.resize(len(face_texture_paths))
		
		var file := File.new()
		for face_number in len(face_texture_paths):
			var sha256 := file.get_sha256(face_texture_paths[face_number])
			if sha256.empty():
				push_warning(
						"Failed to get sha256 of the contents of “%s”. Hashing its path instead…"
						% [face_texture_paths[face_number]]
				)
				face_texture_hashes[face_number] = hash(face_texture_paths[face_number])
			else:
				face_texture_hashes[face_number] = sha256
		return "%x" % [hash(face_texture_hashes)]
	
	
	func _update() -> void:
		var face_texture_paths := [
				texture_south.resource_path,
				texture_east.resource_path,
				texture_north.resource_path,
				texture_west.resource_path,
				effective_automap_texture_path(),
				effective_automap_texture_path()
		]
		
		var backing_texture_id = _backing_texture_id(face_texture_paths)
		var backing_texture_path := Util.texture_path(OUTPUT_DIR, backing_texture_id)
		var new_backing_texture : Texture
		if ResourceLoader.exists(backing_texture_path):
			new_backing_texture = load(backing_texture_path)
		else:
			var surface_image := Image.new()
			# TODO: What are mipmaps? Should use_mipmaps be true?
			surface_image.create(VSwap.WALL_LENGTH * 3, VSwap.WALL_LENGTH * 2, false, IMAGE_FORMAT)
			for face_number in 6:
				var texture_to_add = load(face_texture_paths[face_number])
				var image_to_add : Image
				if texture_to_add == null:
					push_error(
							"Failed to load “%s”. Using “%s” as a fallback…"
							% [face_texture_paths[face_number], missing_texture.resource_path]
					)
					texture_to_add = missing_texture
					if texture_to_add == null:
						push_error(BLACK_SQUARE_FALLBACK_ERROR)
						image_to_add = Image.new()
						image_to_add.create(
								VSwap.WALL_LENGTH,
								VSwap.WALL_LENGTH,
								false,
								Image.FORMAT_L8
						)
						image_to_add.fill(Color.black)
				if image_to_add == null:
					image_to_add = texture_to_add.get_data()
				
				var row : int = face_number % 3
				var column : int = 0 if face_number < 3 else 1
				image_to_add.resize(
						VSwap.WALL_LENGTH,
						VSwap.WALL_LENGTH,
						Image.INTERPOLATE_NEAREST
				)
				if face_number == 4:
					# Without this, the top texture would appear upside down.
					image_to_add.unlock()
					image_to_add.flip_x()
					image_to_add.flip_y()
					image_to_add.lock()
				surface_image.blit_rect(
						image_to_add,
						Rect2(0, 0, VSwap.WALL_LENGTH, VSwap.WALL_LENGTH),
						Vector2(row * VSwap.WALL_LENGTH, column * VSwap.WALL_LENGTH)
				)
			new_backing_texture = ImageTexture.new()
			new_backing_texture.create_from_image(
					surface_image,
					Texture.FLAGS_DEFAULT & ~Texture.FLAG_FILTER
			)
			backing_texture_path = Util.save_texture(
					new_backing_texture,
					OUTPUT_DIR,
					backing_texture_id
			)
			new_backing_texture.take_over_path(backing_texture_path)
		base = new_backing_texture


var missing_texture : Texture = load(Util.missing_texture_path())
export var texture_east : Texture = missing_texture setget set_texture_east
export var texture_north : Texture = missing_texture setget set_texture_north
export var texture_south : Texture = missing_texture setget set_texture_south
export var texture_west : Texture = missing_texture setget set_texture_west


func _update_material() -> void:
	var new_albedo_texture = WallTexture.new()
	new_albedo_texture.texture_east = texture_east
	new_albedo_texture.texture_north = texture_north
	new_albedo_texture.texture_south = texture_south
	new_albedo_texture.texture_west = texture_west
	
	var new_material := SpatialMaterial.new()
	new_material.flags_unshaded = true
	new_material.albedo_texture = new_albedo_texture
	mesh.surface_set_material(0, new_material)


# This ensures that _update_material() gets run at most once per physics tic.
# Without something like this, the following code would unnecessarily run
# _update_material() multiple times:
#     set_texture_east(missing_texture)
#     set_texture_north(missing_texture)
#     set_texture_south(missing_texture)
#     set_texture_west(missing_texture)
func _physics_process(_delta) -> void:
	_update_material()
	set_physics_process(false)


func queue_update_material() -> void:
	set_physics_process(true)


func set_texture_east(new_texture_east : Texture) -> void:
	texture_east = new_texture_east
	queue_update_material()


func set_texture_north(new_texture_north : Texture) -> void:
	texture_north = new_texture_north
	queue_update_material()


func set_texture_south(new_texture_south : Texture) -> void:
	texture_south = new_texture_south
	queue_update_material()


func set_texture_west(new_texture_west : Texture) -> void:
	texture_west = new_texture_west
	queue_update_material()
