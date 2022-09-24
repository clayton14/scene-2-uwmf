extends Reference


const Gdunzip = preload("res://addons/gdunzip/gdunzip.gd")

var path: String setget set_path


func set_path(new_path: String) -> bool:
	var gdunzip := Gdunzip.new()
	if !gdunzip.load(new_path):
		push_error("Failed to load “%s” as a ZIP file." % [new_path])
		return false
	
	path = new_path
	return true


func _init(initial_path: String) -> void:
	# warning-ignore:return_value_discarded
	set_path(initial_path)
