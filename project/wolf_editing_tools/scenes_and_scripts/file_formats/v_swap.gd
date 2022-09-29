# See these Wolfenstein 3D game file specifications for information about the
# VSWAP file format: <https://vpoupet.github.io/wolfenstein/docs/files>
extends Reference
class_name VSwap


const BASE_INVALID_VSWAP_ERROR := "Invalid VSWAP file “%s” "
const MISSING_TOTAL_CHUNKS := BASE_INVALID_VSWAP_ERROR + "(file is not large enough to contain total chunks number)"
const MISSING_FIRST_SPRITE_INDEX := BASE_INVALID_VSWAP_ERROR + "(file is not large enough to contain first sprite index number)"
const MISSING_FIRST_SOUND_INDEX := BASE_INVALID_VSWAP_ERROR + "(file is not large enough to contain first sound index number)"
const MISSING_CHUNK_STARTS := BASE_INVALID_VSWAP_ERROR + "(file is not large enough to contain an address for each chunk)"
const MISSING_CHUNK_LENGTHS := BASE_INVALID_VSWAP_ERROR + "(file is not large enough to contain a length for each chunk)"
const WRONG_NUMBER_OF_COLORS := "The palette should have %s colors, but it actually has %s colors."
const TOO_FEW_COLORS := WRONG_NUMBER_OF_COLORS + " This will probably cause a fatal error later."
const DEFAULTING_TO_PALETTE := "Defaulting to palette for VSWAP.WL6…"
const LACKS_EXTENSION := "VSWAP file “%s” lacks a file extension. " + DEFAULTING_TO_PALETTE
const MISSING_PALETTE := "Couldn’t find palette for “%s” in provided ecwolf.pk3. " + DEFAULTING_TO_PALETTE
const MISSING_DATA_MAP := "Couldn’t find data map for “%s” in provided ecwolf.pk3. Defaulting to data map for VSWAP.WL6…"
const WALL_CHUNK_WRONG_SIZE := "Wall chunk #%s should be %s bytes, but it’s actually %s bytes."
const WALL_CHUNK_TOO_SMALL := WALL_CHUNK_WRONG_SIZE + " Skipping that wall…"
const WALL_CHUNK_TOO_LARGE := WALL_CHUNK_WRONG_SIZE + " Ignoring extra bytes…"
const RAN_OUT_OF_WALL_NAMES := "Ran out of names for walls. Total wall names: %s. Total walls: %s. Skipping wall #%s and every wall after it…"
const WALL_LENGTH := 64  # Unit: pixels
const EXPECTED_WALL_SIZE := WALL_LENGTH * WALL_LENGTH  # Unit: bytes

var ecwolf_pk3 : Pk3 setget set_ecwolf_pk3
var v_swap_path setget set_v_swap_path
var walls := {}


func _next_uint16_or_null(file : File, failure_message : String):
	# The current position is one byte large, so
	# file.get_position() + 1 byte = 2 bytes
	# 2 bytes is the size of a unit16.
	if file.get_position() + 1 < file.get_len():
		return file.get_16()
	else:
		push_error(failure_message)
		return null


func _next_uint32_or_null(file : File, failure_message : String):
	# The current position is one byte large, so
	# file.get_position() + 3 byte = 4 bytes
	# 4 bytes is the size of a unit32.
	if file.get_position() + 3 < file.get_len():
		return file.get_32()
	else:
		push_error(failure_message)
		return null


func get_value_or_fallback_to_wl6(dictionary: Dictionary, missing_key_warning: String):
	var file_extension : String = v_swap_path.get_extension()
	if file_extension.empty():
		push_warning(LACKS_EXTENSION % [v_swap_path])
		file_extension = "wl6"
	else:
		file_extension = file_extension.to_lower()
	
	var return_value = dictionary.get(file_extension)
	if return_value == null:
		push_warning(missing_key_warning)
		return_value = dictionary["wl6"]
	return return_value


func palette() -> Array:
	var return_value = get_value_or_fallback_to_wl6(ecwolf_pk3.palettes, MISSING_PALETTE % [v_swap_path])
	
	if len(return_value) < Pk3.TOTAL_COLORS_IN_PALETTE:
		push_error(TOO_FEW_COLORS % [Pk3.TOTAL_COLORS_IN_PALETTE, return_value])
	elif len(return_value) > Pk3.TOTAL_COLORS_IN_PALETTE:
		push_warning(WRONG_NUMBER_OF_COLORS % [Pk3.TOTAL_COLORS_IN_PALETTE, return_value])
	
	return return_value


func wall_names() -> Array:
	var data_map = get_value_or_fallback_to_wl6(ecwolf_pk3.data_maps, MISSING_DATA_MAP % [v_swap_path])
	return data_map["textures"]


func set_v_swap_path(new_v_swap_path : String) -> bool:
	var file := File.new()
	if file.open(new_v_swap_path, File.READ) != OK:
		push_error("Failed to open “%s” for reading." % [new_v_swap_path])
		return false
	
	var total_chunks = _next_uint16_or_null(file, MISSING_TOTAL_CHUNKS % [new_v_swap_path])
	if total_chunks == null:
		return false
	var first_sprite_index = _next_uint16_or_null(file, MISSING_FIRST_SPRITE_INDEX % [new_v_swap_path])
	if first_sprite_index == null:
		return false
	var first_sound_index = _next_uint16_or_null(file, MISSING_FIRST_SOUND_INDEX % [new_v_swap_path])
	if first_sound_index == null:
		return false
	
	var chunk_addresses := []
	chunk_addresses.resize(total_chunks)
	for i in total_chunks:
		chunk_addresses[i] = _next_uint32_or_null(file, MISSING_CHUNK_STARTS % [new_v_swap_path])
		if chunk_addresses[i] == null:
			return false
	var chunk_lengths := []
	chunk_lengths.resize(total_chunks)
	for i in total_chunks:
		chunk_lengths[i] = _next_uint16_or_null(file, MISSING_CHUNK_STARTS % [new_v_swap_path])
		if chunk_lengths[i] == null:
			return false
	
	walls.clear()
	var palette : Array = palette()
	var wall_names : Array = wall_names()
	# All of the indexes before first_sprite_index are for walls
	for wall_index in first_sprite_index:
		var wall_length : int = chunk_lengths[wall_index]
		if wall_length < EXPECTED_WALL_SIZE:
			push_error(WALL_CHUNK_TOO_SMALL % [wall_index, EXPECTED_WALL_SIZE, wall_length])
		else:
			if wall_length > EXPECTED_WALL_SIZE:
				push_error(WALL_CHUNK_TOO_LARGE % [wall_index, EXPECTED_WALL_SIZE, wall_length])
			if len(wall_names) <= wall_index:
				push_error(RAN_OUT_OF_WALL_NAMES % [len(wall_names), first_sprite_index, wall_index])
				break
			else:
				file.seek(chunk_addresses[wall_index])
				var wall_image := Image.new()
				# TODO: What are mipmaps? Should use_mipmaps be true?
				wall_image.create(WALL_LENGTH, WALL_LENGTH, false, Image.FORMAT_RGB8)
				wall_image.lock()
				for column in WALL_LENGTH:
					for row in WALL_LENGTH:
						var color_number : int = file.get_8()
						wall_image.set_pixel(column, row, palette[color_number])
				wall_image.unlock()
				
				var wall_name : String = wall_names[wall_index]
				var wall_texture := ImageTexture.new()
				wall_texture.create_from_image(wall_image, Texture.FLAGS_DEFAULT - Texture.FLAG_FILTER)
				walls[wall_name] = wall_texture
		
	v_swap_path = new_v_swap_path
	return true


func set_ecwolf_pk3(new_ecwolf_pk3 : Pk3) -> bool:
	ecwolf_pk3 = new_ecwolf_pk3
	if set_v_swap_path(v_swap_path):
		return true
	else:
		push_error("Failed to load VSWAP file “%s”." % [v_swap_path])
		return false


func _init(initial_ecwolf_pk3: Pk3, inital_v_swap_path: String) -> void:
	v_swap_path = inital_v_swap_path
	if !set_ecwolf_pk3(initial_ecwolf_pk3):
		v_swap_path = null
