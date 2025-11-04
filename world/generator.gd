class_name Generator extends Node

enum Type {
	EMPTY,
	SUPERFLAT,
	NOISE,
}

var _type = Type.EMPTY

func _init(type: Type) -> void:
	_type = type

func generate(index: Vector3i) -> Dictionary[Vector3i, Block.Type]:
	match _type:
		Type.SUPERFLAT:
			return _superflat(index)
		Type.NOISE:
			return _noise(index)
	return _empty(index)

func _empty(_index: Vector3i) -> Dictionary[Vector3i, Block.Type]:
	return {}

func _superflat(_index: Vector3i) -> Dictionary[Vector3i, Block.Type]:
	var blocks: Dictionary[Vector3i, Block.Type] = {}
	for x in range(0, Chunk.WIDTH):
		for z in range(0, Chunk.WIDTH):
			var index = Vector3i(x, 0, z)
			blocks[index] = Block.Type.GRASS
	return blocks

func _noise(_index: Vector3i) -> Dictionary[Vector3i, Block.Type]:
	return {}
