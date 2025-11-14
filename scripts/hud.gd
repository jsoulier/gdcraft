class_name HUD extends Control

@onready var _block: TextureRect = $Block

func _ready() -> void:
	pass
	
func _on_player_switch_block(type: Block.Type) -> void:
	var start = Block.get_face_index(type, Block.Face.FORWARD) * Spritesheet.SIZE
	_block.texture.region = Rect2(start.x, start.y, Spritesheet.SIZE, Spritesheet.SIZE)
