tool
extends MapObject


func _init() -> void:
	if Engine.editor_hint:
		# TODO: The documentation for NOTIFICATION_TRANSFORM_CHANGED says that I
		# shouldn’t need to do this when the code is running in the editor.
		# Why are the docs wrong?
		set_notify_transform(true)


func _notification(what) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		global_transform.origin = global_transform.origin.round()
		global_transform.basis = Basis.IDENTITY
