tool
extends MapSpotLockedObject


const DEFAULT_ACTIVE_COLOR := Color.green


export var action_number := -1
export var player_cross := false


func to_uwmf() -> String:
	var position := uwmf_position()
	var contents := {
		"x" : int(position.x),
		"y" : int(position.y),
		"z" : int(position.z),
		"action" : action_number
	}
	# In UWMF, playerCross defaults to false. We can save space by not including
	# it when it’s false.
	if player_cross:
		contents["playerCross"] = true
	return Util.named_block(
		"trigger",
		contents
	)

func max_uwmf_x_y_z() -> Vector3:
	# TODO: Make Tile’s version of this function also use Vector3.ONE.
	return uwmf_position() + Vector3.ONE


func east_face_material() -> SpatialMaterial:
	var node : Node = $EastFace
	if node != null:
		if node is MeshInstance:
			if node.get_surface_material_count() < 1:
				push_error("EastFace didn’t have a material.")
			else:
				var material = node.get_surface_material(0)
				if material is SpatialMaterial:
					return material
				else:
					push_error("EastFace’s material wasn’t a SpatialMaterial.")
		else:
			push_error("EastFace wasn’t a MeshInstance.")
	return null


func _get_property_list() -> Array:
	return [
		{
			"name" : "action",  # action is a deprecated alias for action_number
			"type" : typeof(action_number),
			"usage" : PROPERTY_USAGE_NOEDITOR & ~PROPERTY_USAGE_STORAGE
		},
		{
			"name" : "active_color",
			"type" : typeof(Color.green),
			"usage" : PROPERTY_USAGE_DEFAULT & ~PROPERTY_USAGE_STORAGE
		}
	]


func _get(property):
	match property:
		"action":
			return action_number
		"active_color":
			var material := east_face_material()
			if material != null:
				return material.albedo_color

	return null


func _set(property, value) -> bool:
	match property:
		"action":
			if value is int:
				action_number = value
			else:
				push_error(
					("Tried to set action (deprecated) to %s which is not an "
					+ "int. Ignoring…")
					% [value]
				)
		"active_color":
			if value is Color:
				var material := east_face_material()
				if material != null:
					material.albedo_color = value
					return true
			else:
				push_error("Tried to set active_color to a %s instead of a Color." % [value])
	return false


func property_can_revert(name) -> bool:
	return name == "active_color" and get("active_color") != DEFAULT_ACTIVE_COLOR


func property_get_revert(name):
	if name == "active_color":
		return DEFAULT_ACTIVE_COLOR
	else:
		return null
