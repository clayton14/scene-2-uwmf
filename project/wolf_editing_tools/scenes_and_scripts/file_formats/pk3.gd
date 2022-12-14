extends Reference
class_name Pk3


enum Token {
	NAMED_BLOCK_NAME,
	BLOCK_START,
	ANYTHING_FOLLOWED_BY_A_CLOSING_PARENTHESIS
	ITEM_START_OR_BLOCK_END,
	ITEM_CONTENTS_OR_ITEM_END,
	ANYTHING_FOLLOWED_BY_A_COMMA_OR_BLOCK_END,
}

const Gdunzip := preload("res://addons/gdunzip/gdunzip.gd")
const DATA_MAP_FILE_ENDING := "map.txt"
const UNKNOWN_TOKEN_WHILE_GENERATING_WARNING := "While generating the message for another warning, encountered unknown Token: %s"
const UNEXPECTED_CHARACTERS_WARNING := "While looking for %s, found unexpected characters: %s"
const PALETTE_LOCATIONS := {
	"n3d": "noahpal.lmp",
	"sd2": "spearpal.lmp",
	"sd3": "spearpal.lmp",
	"sdm": "spearpal.lmp",
	"sod": "spearpal.lmp",
	"wl1": "wolfpal.lmp",
	"wl6": "wolfpal.lmp",
}
const FAILED_TO_DECOMPRESS := "Failed to decompress “%s” from “%s”."
const MISSING_TEXTURE_PATH := "textures/-noflat-.png"
const NO_MISSING_TEXTURE := " missing_texture will be null."
const NOT_A_PNG := "“%s” from archive “%s” couldn’t be loaded as a PNG." + NO_MISSING_TEXTURE
const TOTAL_COLORS_IN_PALETTE := 256

var _is_whitespace_regex: RegEx = RegEx.new()
var archive_path: String setget set_archive_path
# These are the files that give names to data stored in
# the base game files (the .WL6, .SOD, etc. files).
# See <https://maniacsvault.net/ecwolf/wiki/WL6_Maps>.
var data_maps: Dictionary setget , get_data_maps
var palettes: Dictionary setget , get_palettes
var missing_texture : Texture setget , get_missing_texture


static func is_data_map_file(path: String) -> bool:
	return (not "/" in path) and (path.ends_with(DATA_MAP_FILE_ENDING))


func get_data_maps() -> Dictionary:
	return data_maps


func get_missing_texture() -> Texture:
	return missing_texture


func get_palettes() -> Dictionary:
	return palettes


func is_whitespace(string: String) -> bool:
	if !_is_whitespace_regex.is_valid():
		var regex_pattern := "\\s"
		if _is_whitespace_regex.compile(regex_pattern) != OK:
			push_error("Failed to compile regex pattern “%s”." % [regex_pattern])
			return false
	var regex_match := _is_whitespace_regex.search(string)
	return \
		regex_match != null \
		and regex_match.get_start() == 0 \
		and regex_match.get_end() == len(string)


func warn_if_unexpected_characters(characters: String, expected_token) -> void:
	if !characters.empty():
		var description_of_expected_token: String
		match expected_token:
			Token.NAMED_BLOCK_NAME:
				description_of_expected_token = "a named block name (in “foo { … }”, the named block name is “foo”)"
			Token.BLOCK_START:
				description_of_expected_token = "a block start ({)"
			Token.ITEM_START_OR_BLOCK_END:
				description_of_expected_token = 'the start of an item (") or the endo of a block (})'
			_:
				push_warning(UNKNOWN_TOKEN_WHILE_GENERATING_WARNING % [expected_token])
				description_of_expected_token = var2str(expected_token)
		push_warning(
			UNEXPECTED_CHARACTERS_WARNING \
			% [description_of_expected_token, var2str(characters)]
		)


func _update_data_map(
	base_game_data_extension: String,
	unparsed_data_map: String
) -> void:
	data_maps[base_game_data_extension] = {}

	var current_token = null
	var looking_for = Token.NAMED_BLOCK_NAME
	var in_single_line_comment := false
	var in_multiline_comment := false
	var named_block_name := ""
	var item_contents := ""
	var unexpected_characters := ""
	var i := 0
	while i < len(unparsed_data_map):
		var _debug_current_character : String = unparsed_data_map[i]
		if in_single_line_comment:
			if unparsed_data_map[i] == "\n":
				in_single_line_comment = false
		elif in_multiline_comment:
			if unparsed_data_map.substr(i, 2) == "*/":
				in_multiline_comment = false
				i += 1
		else:
			var current_plus_next := unparsed_data_map.substr(i, 2)
			if current_plus_next == "//":
				in_single_line_comment = true
				i += 1
			elif current_plus_next == "/*":
				in_multiline_comment = true
				i += 1
			else:
				if current_token == null and !is_whitespace(unparsed_data_map[i]):
					current_token = looking_for
				match current_token:
					null:
						pass
					Token.NAMED_BLOCK_NAME:
						if is_whitespace(unparsed_data_map[i]) or unparsed_data_map[i] == "(":
							data_maps[base_game_data_extension][named_block_name] = []

							if unparsed_data_map[i] == "(":
								current_token = Token.ANYTHING_FOLLOWED_BY_A_CLOSING_PARENTHESIS
							else:
								current_token = null
								looking_for = Token.BLOCK_START
						else:
							named_block_name += unparsed_data_map[i]
					Token.ANYTHING_FOLLOWED_BY_A_CLOSING_PARENTHESIS:
						if unparsed_data_map[i] == ")":
							current_token = null
							looking_for = Token.BLOCK_START
					Token.BLOCK_START:
						if unparsed_data_map[i] == "{":
							current_token = null
							looking_for = Token.ITEM_START_OR_BLOCK_END
							warn_if_unexpected_characters(
								unexpected_characters,
								Token.BLOCK_START
							)
						else:
							unexpected_characters += unparsed_data_map[i]
					Token.ITEM_START_OR_BLOCK_END:
						if unparsed_data_map[i] == '"':
							current_token = Token.ITEM_CONTENTS_OR_ITEM_END
							warn_if_unexpected_characters(
								unexpected_characters,
								Token.ITEM_START_OR_BLOCK_END
							)
						elif unparsed_data_map[i] == "}":
							named_block_name = ""
							current_token = null
							looking_for = Token.NAMED_BLOCK_NAME
							warn_if_unexpected_characters(
								unexpected_characters,
								Token.ITEM_START_OR_BLOCK_END
							)
						else:
							unexpected_characters += unparsed_data_map[i]
					Token.ITEM_CONTENTS_OR_ITEM_END:
						if unparsed_data_map[i] == '"':
							data_maps[base_game_data_extension][named_block_name].append(item_contents)
							item_contents = ""

							current_token = null
							looking_for = Token.ANYTHING_FOLLOWED_BY_A_COMMA_OR_BLOCK_END
						else:
							item_contents += unparsed_data_map[i]
					Token.ANYTHING_FOLLOWED_BY_A_COMMA_OR_BLOCK_END:
						if unparsed_data_map[i] == ',':
							current_token = null
							looking_for = Token.ITEM_START_OR_BLOCK_END
						elif unparsed_data_map[i] == '}':
							named_block_name = ""

							current_token = null
							looking_for = Token.NAMED_BLOCK_NAME
					_:
						push_error("Unknown Token: %s" % [current_token])
		i += 1


# ECWolf uses this format for palettes: <https://doomwiki.org/wiki/Palette>
func _update_palettes(path_to_palette: Dictionary) -> void:
	for path in path_to_palette:
		var raw_palette = path_to_palette[path]
		path_to_palette[path] = []
		path_to_palette[path].resize(TOTAL_COLORS_IN_PALETTE)
		for i in TOTAL_COLORS_IN_PALETTE:
			path_to_palette[path][i] = Color8(
				raw_palette[3*i],
				raw_palette[3*i + 1],
				raw_palette [3*i + 2]
			)
	for file_extension in PALETTE_LOCATIONS:
		palettes[file_extension] = path_to_palette.get(PALETTE_LOCATIONS[file_extension])


func set_archive_path(new_archive_path: String) -> bool:
	var gdunzip := Gdunzip.new()
	if !gdunzip.load(new_archive_path):
		push_error("Failed to load “%s” as a ZIP file." % [new_archive_path])
		return false
	# data_map
	for path in gdunzip.files.keys():
		if is_data_map_file(path):
			var base_game_data_extension: String
			base_game_data_extension = path.substr(0, len(path) - len(DATA_MAP_FILE_ENDING))
			data_maps[base_game_data_extension] = null
			var uncompressed = gdunzip.uncompress(path)
			if uncompressed:
				var unparsed_data_map: String = uncompressed.get_string_from_utf8()
				_update_data_map(base_game_data_extension, unparsed_data_map)
			else:
				push_error(FAILED_TO_DECOMPRESS % [path, new_archive_path])
	# palettes
	var path_to_palette = {}
	for path in PALETTE_LOCATIONS.values():
		var uncompressed = gdunzip.uncompress(path)
		if uncompressed:
			path_to_palette[path] = uncompressed
		else:
			push_warning((FAILED_TO_DECOMPRESS + " Skipping that palette…") % [path, new_archive_path])
	_update_palettes(path_to_palette)
	# missing_texture
	var uncompressed = gdunzip.uncompress(MISSING_TEXTURE_PATH)
	if uncompressed:
		var image := Image.new()
		if image.load_png_from_buffer(uncompressed) != OK:
			push_error(NOT_A_PNG % [MISSING_TEXTURE_PATH, new_archive_path])
		var image_texture := ImageTexture.new()
		image_texture.create_from_image(image, Texture.FLAGS_DEFAULT & ~Texture.FLAG_FILTER)
		missing_texture = image_texture
	else:
		push_error((FAILED_TO_DECOMPRESS + NO_MISSING_TEXTURE) % [MISSING_TEXTURE_PATH])

	archive_path = new_archive_path
	return true


func _init(initial_archive_path: String) -> void:
	# warning-ignore:return_value_discarded
	set_archive_path(initial_archive_path)
