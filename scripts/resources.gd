class_name Resources extends Node

const SIZE = 16
const SPRITESHEET = preload("res://resources/spritesheet.png")
const OPAQUE = preload("res://resources/opaque.gdshader")
const TRANSPARENT = preload("res://resources/transparent.gdshader")

var opaque_material: ShaderMaterial = null
var transparent_material: ShaderMaterial = null

func _init() -> void:
	var spritesheet = _create_spritesheet()
	opaque_material = ShaderMaterial.new()
	opaque_material.shader = OPAQUE
	opaque_material.set_shader_parameter("spritesheet", spritesheet)
	opaque_material.render_priority = 0
	transparent_material = ShaderMaterial.new()
	transparent_material.shader = TRANSPARENT
	transparent_material.set_shader_parameter("spritesheet", spritesheet)
	transparent_material.render_priority = 0

func _create_spritesheet() -> Texture2DArray:
	var image = SPRITESHEET.get_image()
	if image.is_compressed():
		image.decompress()
	@warning_ignore_start("integer_division")
	var columns = image.get_width() / SIZE 
	var rows = image.get_height() / SIZE 
	@warning_ignore_restore("integer_division")
	var images = []
	for y in range(rows):
		for x in range(columns):
			var layer = Image.create_empty(SIZE, SIZE, true, image.get_format())
			for i in range(SIZE):
				for j in range(SIZE):
					var color = image.get_pixel(x * SIZE + i, y * SIZE + j)
					layer.set_pixel(i, j, color)
			layer.generate_mipmaps()
			images.append(layer)
	var texture_array = Texture2DArray.new()
	texture_array.create_from_images(images)
	return texture_array
