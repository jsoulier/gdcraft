class_name Spritesheet
extends Node

static var _spritesheet = preload("res://world/spritesheet.png")

static func get_spritesheet() -> Texture2DArray:
	# Load the full texture as an Image
	var img = _spritesheet.get_image()

	var sprite_size = 16
	var sprites_per_row = img.get_width() / sprite_size
	var sprites_per_col = img.get_height() / sprite_size
	var total_layers = int(sprites_per_row * sprites_per_col)

	# Create an array to hold all sprite images
	var images = []

	# Loop over rows and columns to extract each sprite
	for y in range(int(sprites_per_col)):
		for x in range(int(sprites_per_row)):
			var layer_img = Image.create_empty(sprite_size, sprite_size, false, img.get_format())
			for i in range(sprite_size):
				for j in range(sprite_size):
					var color = img.get_pixel(x * sprite_size + i, y * sprite_size + j)
					layer_img.set_pixel(i, j, color)
			images.append(layer_img)

	# Create the Texture2DArray from the array of Images
	var tex_array = Texture2DArray.new()
	tex_array.create_from_images(images)

	return tex_array
