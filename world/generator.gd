class_name Generator extends Node

enum Type {
	EMPTY,
	_1X1X1,
	SUPERFLAT,
	NOISE,
}

var _type = Type.EMPTY
var _generator := FastNoiseLite.new()

func _init(type: Type) -> void:
	_type = type
	_generator.seed = 1337
	_generator.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_generator.frequency = 0.05

func generate(index: Vector3i) -> PackedInt32Array:
	match _type:
		Type.SUPERFLAT:
			return _superflat(index)
		Type._1X1X1:
			return _1x1x1(index)
		Type.NOISE:
			return _noise(index)
	return _empty(index)

func _allocate() -> PackedInt32Array:
	var blocks = PackedInt32Array()
	blocks.resize(Chunk.WIDTH * Chunk.HEIGHT * Chunk.WIDTH)
	blocks.fill(Block.Type.EMPTY)
	return blocks

func _empty(_index: Vector3i) -> PackedInt32Array:
	return _allocate()

func _superflat(_index: Vector3i) -> PackedInt32Array:
	var blocks = _allocate()
	if _index.y != 0:
		return blocks
	for x in range(0, Chunk.WIDTH):
		for z in range(0, Chunk.WIDTH):
			var idx = x + Chunk.WIDTH * (z + Chunk.WIDTH * 0)
			blocks[idx] = Block.Type.GRASS
	return blocks

func _1x1x1(_index: Vector3i) -> PackedInt32Array:
	var blocks = _allocate()
	blocks[0] = Block.Type.GRASS
	return blocks
	
func _noise(_index: Vector3i) -> PackedInt32Array:
	var blocks = _allocate()
	var max_height = 10
	var start_y = _index.y * Chunk.HEIGHT
	for x in range(0, Chunk.WIDTH):
		for z in range(0, Chunk.WIDTH):
			var block_x = _index.x * Chunk.WIDTH + x
			var block_z = _index.z * Chunk.WIDTH + z
			var noise = _generator.get_noise_2d(block_x, block_z)
			var noise_y = int((noise + 1.0) * 0.5 * max_height)
			var end_y = min(start_y + Chunk.HEIGHT, noise_y)
			for y in range(start_y, end_y):
				var world_y = start_y + y
				var index = Chunk.get_block_index(Vector3i(x, y - start_y, z)) 
				if world_y == noise_y - 1:
					blocks[index] = Block.Type.GRASS
				elif world_y > noise_y - 4:
					blocks[index] = Block.Type.DIRT
				else:
					blocks[index] = Block.Type.STONE
	return blocks
