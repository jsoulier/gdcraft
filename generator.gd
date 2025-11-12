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

func generate(index: Vector3i) -> Dictionary[Vector3i, Block.Type]:
	match _type:
		Type.SUPERFLAT:
			return _superflat(index)
		Type._1X1X1:
			return _1x1x1(index)
		Type.NOISE:
			return _noise(index)
	return _empty(index)

func _empty(_index: Vector3i) -> Dictionary[Vector3i, Block.Type]:
	return {}

func _superflat(_index: Vector3i) -> Dictionary[Vector3i, Block.Type]:
	var blocks: Dictionary[Vector3i, Block.Type] = {}
	if _index.y != 0:
		return blocks
	for x in range(0, Chunk.WIDTH):
		for z in range(0, Chunk.WIDTH):
			blocks[Vector3i(x, 0, z)] = Block.Type.GRASS
	return blocks

func _1x1x1(_index: Vector3i) -> Dictionary[Vector3i, Block.Type]:
	return {Vector3i(0, 0, 0): Block.Type.GRASS}
	
func _noise(_index: Vector3i) -> Dictionary[Vector3i, Block.Type]:
	var blocks: Dictionary[Vector3i, Block.Type] = {}
	var max_ground_y = 10
	var sea_level = 5
	var start_y = _index.y * Chunk.HEIGHT
	for x in range(0, Chunk.WIDTH):
		for z in range(0, Chunk.WIDTH):
			var block_x = _index.x * Chunk.WIDTH + x
			var block_z = _index.z * Chunk.WIDTH + z
			var noise = _generator.get_noise_2d(block_x, block_z)
			var ground_y = int((noise + 1.0) * 0.5 * max_ground_y)
			var end_y = min(start_y + Chunk.HEIGHT, max(ground_y, sea_level))
			for y in range(start_y, end_y):
				var world_y = start_y + y
				var index = Vector3i(x, y - start_y, z)
				if world_y > ground_y:
					blocks[index] = Block.Type.WATER
				elif world_y == ground_y - 1:
					blocks[index] = Block.Type.GRASS
				elif world_y > ground_y - 4:
					blocks[index] = Block.Type.DIRT
				else:
					blocks[index] = Block.Type.STONE
	return blocks
