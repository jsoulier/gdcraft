class_name Spritesheet extends Node

const _SIZE = 16

static var _spritesheet = preload("res://resources/spritesheet.png")

static func get_spritesheet() -> Texture2DArray:
	var image = _spritesheet.get_image()
	if image.is_compressed():
		image.decompress()
	@warning_ignore_start("integer_division")
	var columns = image.get_width() / _SIZE 
	var rows = image.get_height() / _SIZE 
	@warning_ignore_restore("integer_division")
	var images = []
	for y in range(rows):
		for x in range(columns):
			# TODO: refactor
			var layer = Image.create_empty(_SIZE, _SIZE, true, image.get_format())
			for i in range(_SIZE):
				for j in range(_SIZE):
					var color = image.get_pixel(x * _SIZE + i, y * _SIZE + j)
					layer.set_pixel(i, j, color)
			layer.generate_mipmaps()
			images.append(layer)
	var texture_array = Texture2DArray.new()
	texture_array.create_from_images(images)
	return texture_array
