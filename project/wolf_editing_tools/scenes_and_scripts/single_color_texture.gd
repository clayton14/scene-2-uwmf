tool
class_name SingleColorTexture
extends ImageTexture


export var color : Color setget set_color, get_color


func _init() -> void:
	set_color(Color.white)


func set_color(new_color : Color) -> void:
	var new_image = Image.new()
	new_image.create(1, 1, false, Image.FORMAT_RGB8)
	new_image.lock()
	new_image.set_pixelv(Vector2.ZERO, new_color)
	new_image.unlock()
	create_from_image(new_image)


func get_color() -> Color:
	var return_value : Color
	var data := get_data()
	data.lock()
	return_value = data.get_pixelv(Vector2.ZERO)
	data.unlock()
	return return_value
