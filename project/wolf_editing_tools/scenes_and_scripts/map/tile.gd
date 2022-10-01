tool
class_name Tile
extends MeshInstance


const FALLBACK_FACE_TEXTURES := [
	preload("res://wolf_editing_tools/art/e.webp"),
	preload("res://wolf_editing_tools/art/n.webp"),
	preload("res://wolf_editing_tools/art/s.webp"),
	preload("res://wolf_editing_tools/art/w.webp"),
	null
]
const EAST_INDEX := 0
const NORTH_INDEX := 1
const SOUTH_INDEX := 2
const WEST_INDEX := 3
const OVERHEAD_INDEX := 4
const WRONG_FACE_TEXTURES_LENGTH := "new_face_textures has %s elements, but it should have %s elements."
const NOT_A_TEXTURE := "new_face_textures[%s] should be null or a Texture but it’s actually a %s. Ignoring…"
const IMAGE_FORMAT := Image.FORMAT_RGB8
const OUTPUT_DIR := "res://wolf_editing_tools/generated/art/walls/cache/"
const TEXTURE_PROPERTY_NAMES := [
	"east_texture",
	"north_texture",
	"south_texture",
	"west_texture",
	"overhead_texture"
]

# Originally, each face Texture had its own variable. Unfortunately, that caused
# the Tile to run update_material() multiple times when the scene was
# instantiated. I had added a workaround for that problem, but that workaround
# caused problems with scenes that had been instantiated but not added to the
# SceneTree.
var face_textures := FALLBACK_FACE_TEXTURES.duplicate() setget set_face_textures


func _init() -> void:
	# This will prevent errors when running Util.texture_path().
	Util.make_dir_recursive_or_error(OUTPUT_DIR)


static func _albedo_texture_id(new_face_textures : Array) -> String:
	var to_hash := []
	to_hash.resize(len(new_face_textures))
	
	var file := File.new()
	for face_number in len(new_face_textures):
		var new_face_texture : Texture = new_face_textures[face_number]
		var face_texture_path : String = new_face_texture.resource_path
		if new_face_texture is SingleColorTexture:
			to_hash[face_number] = new_face_texture.color
		else:
			var sha256 := file.get_sha256(face_texture_path)
			if sha256.empty():
				push_warning(
						"Failed to get sha256 of the contents of “%s”. Using its path instead…"
						% [face_texture_path]
				)
				to_hash[face_number] = face_texture_path
			else:
				to_hash[face_number] = sha256
	return "%x" % [to_hash.hash()]


static func expected_face_textures_length() -> int:
	return len(FALLBACK_FACE_TEXTURES)


static func generate_surface_material(new_face_textures : Array) -> Material:
	var new_albedo_texture_id = _albedo_texture_id(new_face_textures)
	var new_albedo_texture_path := Util.texture_path(OUTPUT_DIR, new_albedo_texture_id)
	var new_albedo_texture : Texture
	if ResourceLoader.exists(new_albedo_texture_path):
		new_albedo_texture = load(new_albedo_texture_path)
	else:
		var new_albedo_image := Image.new()
		# TODO: What are mipmaps? Should use_mipmaps be true?
		new_albedo_image.create(VSwap.WALL_LENGTH * 3, VSwap.WALL_LENGTH * 2, false, IMAGE_FORMAT)
		for face_number in 6:
			var texture_to_add : Texture = new_face_textures[face_number]
			if texture_to_add == null:
				push_warning("new_face_texture #%s shouldn’t be null")
				texture_to_add = FALLBACK_FACE_TEXTURES[face_number]
				if texture_to_add == null:
					texture_to_add = FALLBACK_FACE_TEXTURES[EAST_INDEX]
			var image_to_add : Image
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
			new_albedo_image.blit_rect(
					image_to_add,
					Rect2(0, 0, VSwap.WALL_LENGTH, VSwap.WALL_LENGTH),
					Vector2(row * VSwap.WALL_LENGTH, column * VSwap.WALL_LENGTH)
			)
		new_albedo_texture = ImageTexture.new()
		new_albedo_texture.create_from_image(
				new_albedo_image,
				Texture.FLAGS_DEFAULT & ~Texture.FLAG_FILTER
		)
		new_albedo_texture_path = Util.save_texture(
				new_albedo_texture,
				OUTPUT_DIR,
				new_albedo_texture_id
		)
		new_albedo_texture.take_over_path(new_albedo_texture_path)
	
	var return_value := SpatialMaterial.new()
	return_value.flags_unshaded = true
	return_value.albedo_texture = new_albedo_texture
	
	return return_value


func effective_overhead_texture() -> Texture:
	# In UWMF, if textureOverhead is unspecified, it defaults to eastTexture.
	# See <https://maniacsvault.net/ecwolf/wiki/UWMF#Optional_Properties>.
	var return_value : Texture
	return_value = face_textures[OVERHEAD_INDEX]
	if return_value == null:
		return_value = face_textures[EAST_INDEX]
	return return_value


func update_material() -> void:
	set_surface_material(
		0,
		generate_surface_material([
			get_south_texture(),
			get_east_texture(),
			get_north_texture(),
			get_west_texture(),
			effective_overhead_texture(),
			effective_overhead_texture()
		])
	)


# This ensures that update_material() gets run at most once per physics tic.
# Without something like this, the following code would unnecessarily run
# update_material() multiple times:
#     set_texture_east(missing_texture)
#     set_texture_north(missing_texture)
#     set_texture_south(missing_texture)
#     set_texture_west(missing_texture)
func _physics_process(_delta) -> void:
	update_material()
	set_physics_process(false)


func queue_update_material() -> void:
	set_physics_process(true)


func set_face_textures(new_face_textures : Array) -> void:
	var actual_length = len(new_face_textures)
	var expected_length = expected_face_textures_length()
	if actual_length != expected_length:
		push_warning(WRONG_FACE_TEXTURES_LENGTH % [actual_length, expected_length]) 
	for i in actual_length:
		var element = new_face_textures[i]
		if element == null or element is Texture:
			face_textures[i] = element
		else:
			push_warning(NOT_A_TEXTURE % [i, element.get_class()])
	update_material()


func set_east_texture(new_east_texture : Texture) -> void:
	var new_face_textures := face_textures.duplicate()
	new_face_textures[EAST_INDEX] = new_east_texture
	set_face_textures(new_face_textures)


func get_east_texture() -> Texture:
	return face_textures[EAST_INDEX]


func set_north_texture(new_north_texture : Texture) -> void:
	var new_face_textures := face_textures.duplicate()
	new_face_textures[NORTH_INDEX] = new_north_texture
	set_face_textures(new_face_textures)


func get_north_texture() -> Texture:
	return face_textures[NORTH_INDEX]


func set_south_texture(new_south_texture : Texture) -> void:
	var new_face_textures := face_textures.duplicate()
	new_face_textures[SOUTH_INDEX] = new_south_texture
	set_face_textures(new_face_textures)


func get_south_texture() -> Texture:
	return face_textures[SOUTH_INDEX]


func set_west_texture(new_west_texture : Texture) -> void:
	var new_face_textures := face_textures.duplicate()
	new_face_textures[WEST_INDEX] = new_west_texture
	set_face_textures(new_face_textures)


func get_west_texture() -> Texture:
	return face_textures[WEST_INDEX]


func set_overhead_texture(new_overhead_texture : Texture) -> void:
	var new_face_textures := face_textures.duplicate()
	new_face_textures[OVERHEAD_INDEX] = new_overhead_texture
	set_face_textures(new_face_textures)


func get_overhead_texture() -> Texture:
	return face_textures[OVERHEAD_INDEX]


func _get_property_list() -> Array:
	var return_value := []
	return_value.resize(len(TEXTURE_PROPERTY_NAMES) + 1)
	for i in len(TEXTURE_PROPERTY_NAMES):
		return_value[i] = {
			"name" : TEXTURE_PROPERTY_NAMES[i],
			"type" : typeof(FALLBACK_FACE_TEXTURES[0]),
			"usage" : PROPERTY_USAGE_DEFAULT & ~PROPERTY_USAGE_STORAGE,
			"hint" : PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string" : "Texture"
		}
	return_value[-1] = {
		"name" : "face_textures",
		"type" : typeof(face_textures),
		"usage" : PROPERTY_USAGE_NOEDITOR
	}
	return return_value


func _get(property):
	# This prevents the material from being saved into the scene file. Here’s
	# why I’m doing that:
	#     1. The Material’s albedo_texture can be generated by looking at
	#        texture_east, texture_north, texture_south and texture_west.
	#        Including it in a saved scene would be redundant.
	#     2. We don’t want users inadvertently distributing copyrighted content
	#        that they don’t own or have a license for (example: walls from
	#        VSWAP.WL6).
	for i in get_surface_material_count():
		if property == "material/%s" % [i]:
			return SpatialMaterial.new()
	
	match property:
		"east_texture":
			return get_east_texture()
		"north_texture":
			return get_north_texture()
		"south_texture":
			return get_south_texture()
		"west_texture":
			return get_west_texture()
		"overhead_texture":
			return get_overhead_texture()
		"face_textures":
			return face_textures


func _set(property, value) -> bool:
	match property:
		"east_texture":
			set_east_texture(value)
			return true
		"north_texture":
			set_north_texture(value)
			return true
		"south_texture":
			set_south_texture(value)
			return true
		"west_texture":
			set_west_texture(value)
			return true
		"overhead_texture":
			set_overhead_texture(value)
			return true
		"face_textures":
			set_face_textures(value)
			return true
	return false


func property_can_revert(property):
	var value = get(property)
	if value is Texture:
		for i in len(TEXTURE_PROPERTY_NAMES):
			if value != FALLBACK_FACE_TEXTURES[i]:
				return true
	return false


func property_get_revert(property):
	for i in len(TEXTURE_PROPERTY_NAMES):
		if property == TEXTURE_PROPERTY_NAMES[i]:
			if FALLBACK_FACE_TEXTURES[i] == null:
				# If you return null, then the property won’t be revertable.
				# Returning Reference.new() allows us to revert the value, and
				# when we do, the value is reverted to null instead of a
				# Reference.
				return Reference.new()
			else:
				return FALLBACK_FACE_TEXTURES[i]
