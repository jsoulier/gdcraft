class_name Generator

enum Type {
	NOISE,
	SUPERFLAT,
	ONE,
}

var type = Type.NOISE
var seed_number = 1337

func _noise(_index: Vector3i, _blocks: Dictionary[Vector3i, Block.Type]) -> void:
	pass

func _superflat(_index: Vector3i, _blocks: Dictionary[Vector3i, Block.Type]) -> void:
	if _index.y != 0:
		return
	for x in range(Chunk.WIDTH):
		for y in range(Chunk.WIDTH):
			_blocks[Vector3i(x, 0, y)] = Block.Type.STONE
			_blocks[Vector3i(x, 1, y)] = Block.Type.STONE
			_blocks[Vector3i(x, 2, y)] = Block.Type.STONE
			_blocks[Vector3i(x, 3, y)] = Block.Type.DIRT
			_blocks[Vector3i(x, 4, y)] = Block.Type.GRASS

func _one(_index: Vector3i, _blocks: Dictionary[Vector3i, Block.Type]) -> void:
	_blocks[Vector3i(0, 0, 0)] = Block.Type.GRASS

func generate(index: Vector3i) -> Dictionary[Vector3i, Block.Type]:
	var blocks: Dictionary[Vector3i, Block.Type] = {}
	match type:
		Type.NOISE:
			_noise(index, blocks)
		Type.SUPERFLAT:
			_superflat(index, blocks)
		Type.ONE:
			_one(index, blocks)
	assert(not blocks.is_empty())
	return blocks
