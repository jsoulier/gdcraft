class_name Generator extends Node

enum Type {
	EMPTY,
	SUPERFLAT,
	ONE,
	NOISE,
}

var _type = Type.EMPTY

func _init(type: Type) -> void:
	_type = type

func generate(index: Vector3i) -> Dictionary[Vector3i, Block.Type]:
	match _type:
		Type.SUPERFLAT:
			return _superflat(index)
		Type.ONE:
			return _one(index)
		Type.NOISE:
			return _noise(index)
	return _empty(index)

func _empty(_index: Vector3i) -> Dictionary[Vector3i, Block.Type]:
	return {}

func _superflat(_index: Vector3i) -> Dictionary[Vector3i, Block.Type]:
	var blocks: Dictionary[Vector3i, Block.Type] = {}
	if _index.y != 0:
		return blocks
	for x in range(0, Chunk._WIDTH):
		for z in range(0, Chunk._WIDTH):
			var index = Vector3i(x, 0, z)
			blocks[index] = Block.Type.GRASS
	return blocks

func _one(_index: Vector3i) -> Dictionary[Vector3i, Block.Type]:
	return {Vector3i(0, 0, 0): Block.Type.GRASS}
	
func _noise(_index: Vector3i) -> Dictionary[Vector3i, Block.Type]:
	return {}
