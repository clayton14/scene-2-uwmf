extends Reference


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

var _is_whitespace_regex: RegEx = RegEx.new()
var archive_path: String setget set_archive_path
# These are the files that give names to data stored in
# the base game files (the .WL6, .SOD, etc. files).
var data_maps: Dictionary
var unparsed_data_map : String


static func is_data_map_file(path: String) -> bool:
	return (not "/" in path) and (path.ends_with(DATA_MAP_FILE_ENDING))


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
		var description_of_looking_for: String
		match expected_token:
			# TODO: Make sure that this has everything
			Token.NAMED_BLOCK_NAME:
				description_of_looking_for = "a named block name (in “foo { … }”, the named block name is “foo”)"
			Token.PARAMETERS_OR_BLOCK_START:
				description_of_looking_for = "a block start ({) or a parameter list [a “(” followed by anything followed by a “)”]"
			Token.ITEM_START_OR_BLOCK_END:
				description_of_looking_for = 'the start of an item (") or the endo of a block (})'
			Token.ITEM_CONTENTS:
				description_of_looking_for = 'the contents of an item (in ‘"foo",’, the contents of the item is ‘foo,’)"'
			_:
				push_warning(UNKNOWN_TOKEN_WHILE_GENERATING_WARNING % [expected_token])
				description_of_looking_for = var2str(expected_token)
		push_warning(
			UNEXPECTED_CHARACTERS_WARNING \
			% [description_of_looking_for, var2str(characters)]
		)
		print(characters)
		


func set_archive_path(new_archive_path: String) -> bool:
	var gdunzip := Gdunzip.new()
	if !gdunzip.load(new_archive_path):
		push_error("Failed to load “%s” as a ZIP file." % [new_archive_path])
		return false
	for path in gdunzip.files.keys():
		if is_data_map_file(path):
			var base_game_data_extension: String
			base_game_data_extension = path.substr(0, len(path) - len(DATA_MAP_FILE_ENDING))
			data_maps[base_game_data_extension] = null
			var uncompressed = gdunzip.uncompress(path)
			if uncompressed:
				#var unparsed_data_map: String = uncompressed.get_string_from_utf8()
				unparsed_data_map = uncompressed.get_string_from_utf8()
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
			else:
				push_error("Failed to decompress “%s” from “%s”." % [path, new_archive_path])
	
	archive_path = new_archive_path
	return true


func _init(initial_archive_path: String) -> void:
	# warning-ignore:return_value_discarded
	set_archive_path(initial_archive_path)
