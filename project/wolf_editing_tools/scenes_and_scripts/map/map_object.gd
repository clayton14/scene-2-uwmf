class_name MapObject
extends Spatial


func to_uwmf() -> String:
	push_error("A child class should have overridden this method (to_uwmf()).")
	return ""


func uwmf_position() -> Vector3:
	# Unfortunately, Godot and the UWMF disagree on the names of the axes.
	# Godot name => UWMF name
	# X          => X
	# Y          => Z
	# Z          => Y
	var return_value =  Vector3(
		global_transform.origin.x,
		global_transform.origin.z,
		global_transform.origin.y
	)
	# TODO: Errors for NAN, and ±INF.
	if return_value.x < 0:
		push_error("MapObject has a negative X coordinate.")
	if return_value.y < 0:
		push_error("MapObject has a negative Z coordinate.")
	if return_value.z < 0:
		push_error("MapObject has a negative Y coordinate.")
	
	return return_value


# Returns the largest X coordinate of any point inside this MapObjet,
# the largest Y coordinate of any point indside this MapObject and the largest Z
# coordinate of any point inside this MapObject. 
func max_uwmf_x_y_z() -> Vector3:
	return uwmf_position()
