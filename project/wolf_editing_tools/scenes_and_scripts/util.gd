extends Object
class_name Util


static func property_assignment_statement(property: String, value) -> String:
	# I’m writting property names in all uppercase.
	#
	# When you encode English text in UTF-8, the majority of the bits will probably be zero. Most
	# characters that are used when writting English are in ASCII. All ASCII characters (when
	# encoded using UTF-8) have their eighth bit set to zero.
	#
	# Additionally, all uppercase letters have their sixth bit set to zero. All lowercase letters
	# have their sixth bit set to one.
	#
	# Using uppercase letters means that there will be less variation in the data (most of it will
	# probably be zeros). Less variation probably means better compression.
	return '%s=%s;' % [property.to_upper(), var2str(value)]


static func named_block(name : String, contents : Dictionary) -> String:
	var return_value := name.to_upper() + "{"
	for key in contents:
		# Take a look at the comment in convert_to_uwmf for why I’m doing it
		# like this.
		return_value += property_assignment_statement(key.to_upper(), contents[key])
	return_value += "}"
	return return_value


static func texture_to_uwmf(texture : Texture) -> String:
	if texture is SingleColorTexture:
		return texture.to_uwmf()
	else:
		return "%s" % [texture.resource_path.get_basename().get_file()]


func _init() -> void:
	push_warning("Util is a utillity class. Why are you constructing it?")
