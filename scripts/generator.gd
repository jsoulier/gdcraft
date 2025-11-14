class_name Generator extends Node

enum Type {
	EMPTY,
	_1X1X1,
	SUPERFLAT,
	NOISE,
}

@export var generator_seed = 1337
var _type = Type.EMPTY
var _base_generator := FastNoiseLite.new()
var _overlay_generator := FastNoiseLite.new()
var _foliage_generator := FastNoiseLite.new()
var _tree_generator := FastNoiseLite.new()

func _init(type: Type) -> void:
	_type = type
	_base_generator.seed = generator_seed * 13
	_base_generator.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_base_generator.frequency = 0.01
	_overlay_generator.seed = generator_seed * 79
	_overlay_generator.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_overlay_generator.frequency = 0.1
	_foliage_generator.seed = generator_seed * 53
	_foliage_generator.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_foliage_generator.frequency = 0.05
	_tree_generator.seed = generator_seed * 139
	_tree_generator.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_tree_generator.frequency = 0.05

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

func _can_add_tree(x: int, z: int) -> bool:
	return x > 2 and z > 2 and x < Chunk.SIZE.x - 3 and z < Chunk.SIZE.z - 3	

func _tree(blocks: Dictionary[Vector3i, Block.Type], x: int, y: int, z: int) -> void:
	var height = int((_tree_generator.get_noise_2d(x, z) + 1.0) * 2.0) + 4
	for i in range(height):
		var log_idx = Vector3i(x, y + i, z)
		if Chunk.in_bounds(log_idx):
			blocks[log_idx] = Block.Type.LOG
	for lx in range(-2, 3):
		for ly in range(-2, 3):
			for lz in range(-2, 3):
				if abs(lx) + abs(ly) + abs(lz) > 3:
					continue
				var leaf_idx = Vector3i(x + lx, y + height - 2 + ly, z + lz)
				if Chunk.in_bounds(leaf_idx) and leaf_idx not in blocks:
					blocks[leaf_idx] = Block.Type.LEAVES

func _noise(_index: Vector3i) -> Dictionary[Vector3i, Block.Type]:
	var blocks: Dictionary[Vector3i, Block.Type] = {}
	var sea_level = 10
	var start_y = _index.y * Chunk.HEIGHT
	for x in range(0, Chunk.WIDTH):
		for z in range(0, Chunk.WIDTH):
			var block_x = _index.x * Chunk.WIDTH + x
			var block_z = _index.z * Chunk.WIDTH + z
			var base_noise = (_base_generator.get_noise_2d(block_x, block_z) + 1.0) * 0.5
			var overlay_noise = (_overlay_generator.get_noise_2d(block_x, block_z) + 1.0) * 0.5
			var noise = int(pow(base_noise * 5, 1.25) * 5 + overlay_noise * 2)
			var end_y = min(start_y + Chunk.HEIGHT, max(noise, sea_level))
			for y in range(start_y, end_y):
				var index = Vector3i(x, y - start_y, z)
				assert(Chunk.in_bounds(index))
				if y > noise:
					blocks[index] = Block.Type.WATER
				elif (noise >= sea_level - 1 and noise < sea_level + overlay_noise * 2) \
					or (y > noise - 2 and noise <= sea_level):
					blocks[index] = Block.Type.SAND
				elif y > 20 + overlay_noise * 2:
					blocks[index] = Block.Type.STONE
				elif y == noise - 1:
					blocks[index] = Block.Type.GRASS
					if not _can_add_tree(x, z):
						continue
					var foliage_noise = _foliage_generator.get_noise_2d(block_x, block_z)
					var foliage_probability = int(foliage_noise * 13793) % 100
					if foliage_probability < 2:
						_tree(blocks, x, noise - start_y, z)
				elif y > noise - 4:
					blocks[index] = Block.Type.DIRT
				else:
					blocks[index] = Block.Type.STONE
	return blocks