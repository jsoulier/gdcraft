class_name HUD extends Control

@onready var _block_texture: TextureRect = $BlockHorizontal/BlockVertical/Texture
@onready var _block_text: Label = $BlockHorizontal/BlockVertical/Text
	
func _on_player_switch_block(type: Block.Type) -> void:
	var width = Spritesheet.SIZE
	var start = Block.get_face_index(type, Block.Face.FORWARD) * width
	_block_texture.texture.region = Rect2(start.x, start.y, width, width)
	_block_text.text = Block.Type.keys()[type].to_lower()
