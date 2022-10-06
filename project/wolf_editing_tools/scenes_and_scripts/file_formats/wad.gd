# See the Doom Wiki for information about the WAD file format:
# <https://doomwiki.org/wiki/WAD>
extends Reference


class Lump extends Reference:
	const ASCII_WARNING := "Only ASCII characters are allowed in lump names. Replacing “%s” with “%s”…"
	const LAST_ASCII_CODEPOINT := 127
	const NAME_LENGTH_LIMIT := 8
	const NAME_LENGHT_WARNING := "Lump names can be at most " + str(NAME_LENGTH_LIMIT) + " characters. Truncating “%s” to “%s”…"

	const CONTENTS_SIZE_LIMIT := 0xFF_FF_FF_FF
	const CONTENTS_SIZE_ERROR := \
			"Tried to create a lump who’s contents are 0x%X bytes large. " \
			+ "The contents of a lump may be at most 0x%X bytes." % [CONTENTS_SIZE_LIMIT] \
			+ "Truncating to 0x%X bytes…" % [CONTENTS_SIZE_LIMIT]

	var name: String setget set_name
	var contents: PoolByteArray setget set_contents
	# This get used to remember what should be written to the directory (see
	# <https://doomwiki.org/wiki/WAD#Directory>).
	var _filepos: int

	func set_name(new_name: String) -> void:
		for character in new_name:
			var codepoint := ord(character)
			if codepoint > LAST_ASCII_CODEPOINT:
				var replacement := "U+%04X" % [codepoint]
				push_warning(ASCII_WARNING % [character, replacement])
				new_name = new_name.replace(character, replacement)
		if new_name.length() > NAME_LENGTH_LIMIT:
			var truncated_name := new_name.substr(0, 8)
			push_warning(NAME_LENGHT_WARNING % [new_name, truncated_name])
			new_name = truncated_name

		name = new_name

	func set_contents(new_contents: PoolByteArray) -> void:
		# I don’t think that this condition can be true anyway due to bugs with
		# Godot. See <https://github.com/godotengine/godot/issues/18094> and
		# potentially <https://github.com/godotengine/godot/issues/46842>.
		if contents.size() > CONTENTS_SIZE_LIMIT:
			push_error(CONTENTS_SIZE_ERROR % contents.size())
			new_contents = new_contents.subarray(0, CONTENTS_SIZE_LIMIT - 1)

		contents = new_contents

	func nul_terminated_name() -> PoolByteArray:
		var return_value := name.to_ascii()
		if return_value.size() < NAME_LENGTH_LIMIT:
			return_value.resize(NAME_LENGTH_LIMIT)
			var i = return_value.size()
			while i < NAME_LENGTH_LIMIT:
				return_value.set(i, 0)
				i += 1
		return return_value

	func _init(initial_name: String, initial_contents: PoolByteArray) -> void:
		set_name(initial_name)
		set_contents(initial_contents)


const OPEN_ERROR := "Failed to open “%s” for writting."
# See <https://doomwiki.org/wiki/WAD#Header>.
# Godot doesn’t think that this is a constant expression, so I have to do something that’s uglier.
#const IDENTIFICATION := "PWAD".to_ascii()
const IDENTIFICATION := PoolByteArray([ord("P"), ord("W"), ord("A"), ord("D")])
const MAXIMUM_LUMPS := 0xFF_FF_FF_FF
const DIRECTORY_POINTER_LOCATION := 8
const MAXIMUM_LUMPS_DIRECTORY_LOCATION := 0xFF_FF_FF_FF

var lumps: Array = [] setget set_lumps


# Returns wether or not appending the lump was successful.
func append_lump(lump: Lump) -> bool:
	if len(lumps) + 1 < MAXIMUM_LUMPS:
		lumps.append(lump)
		return true
	else:
		return false

# Returns whether or not setting lumps was successful.
func set_lumps(new_lumps: Array) -> bool:
	if len(new_lumps) < MAXIMUM_LUMPS:
		lumps = new_lumps
		return true
	else:
		return false


# Returns an Error (see
# <https://docs.godotengine.org/en/stable/classes/class_%40globalscope.html#enum-globalscope-error>).
func save(file_path: String) -> int:
	var file = File.new()
	var error_code : int = file.open(file_path, File.WRITE)
	if error_code != OK:
		push_error(OPEN_ERROR % [file_path])
		return error_code

	# Header <https://doomwiki.org/wiki/WAD#Header>
	file.store_buffer(IDENTIFICATION)
	file.store_32(len(lumps))
	file.store_32(0)  # Later, we’ll come back and set this to where the directory actually is.
	# Lump data
	for lump in lumps:
		lump._filepos = file.get_position()
		file.store_buffer(lump.contents)
	# Directory <https://doomwiki.org/wiki/WAD#Directory>
	var directory_offset : int = file.get_position()
	if directory_offset > MAXIMUM_LUMPS_DIRECTORY_LOCATION:
		push_error("Lump data chunk too large.")
		file.close()
		return ERR_INVALID_DATA
	for lump in lumps:
		file.store_32(lump._filepos)
		file.store_32(lump.contents.size())
		file.store_buffer(lump.nul_terminated_name())
	# Fix the directory pointer from before.
	file.seek(DIRECTORY_POINTER_LOCATION)
	file.store_32(directory_offset)

	file.close()
	return OK
