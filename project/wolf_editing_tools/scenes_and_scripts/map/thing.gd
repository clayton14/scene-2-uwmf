extends MapObject


# The UWMF spec says that type should be a string, but the latest stable version
# of ECWolf requires that ints are used. I took a look at ECWolf’s master
# branch, and it looks like using ints for thing types is still supported, but
# deprecated.
export var type := 1
export var skill1 := true
export var skill2 := true
export var skill3 := true
export var skill4 := true


func to_uwmf() -> String:
	var position := uwmf_position()
	var contents := {
		"type" : type,
		"x" : position.x,
		"y" : position.y,
		"z" : position.z
	}
	# According to the UWMF spec, if a skill property is missing, it defaults to
	# false [1]. Not storing a value takes up less space, so we only store a
	# skill property if it’s true.
	#
	# [1]: <https://maniacsvault.net/ecwolf/wiki/Universal_Wolfenstein_Map_Format#Optional_Properties_5>
	if skill1:
		contents["skill1"] = true
	if skill2:
		contents["skill2"] = true
	if skill3:
		contents["skill3"] = true
	if skill4:
		contents["skill4"] = true
	return Util.named_block("thing", contents)
