class_name Generator
extends Node

enum Type {
	NOISE,
	SUPERFLAT,
	DEBUG,
}

@export var type = Type.NOISE
@export var generator_seed = 1337
var _base_generator := FastNoiseLite.new()
var _overlay_generator := FastNoiseLite.new()
var _foliage_generator := FastNoiseLite.new()
var _tree_generator := FastNoiseLite.new()

func _init() -> void:
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

func _noise(index: Vector3i, blocks: Dictionary[Vector3i, Block.Type]) -> void:
	var sea_level = 10
	var start_y = index.y * Chunk.HEIGHT
	for x in range(0, Chunk.WIDTH):
		for z in range(0, Chunk.WIDTH):
			var block_x = index.x * Chunk.WIDTH + x
			var block_z = index.z * Chunk.WIDTH + z
			var base_noise = (_base_generator.get_noise_2d(block_x, block_z) + 1.0) * 0.5
			var overlay_noise = (_overlay_generator.get_noise_2d(block_x, block_z) + 1.0) * 0.5
			var noise = int(pow(base_noise * 5, 1.25) * 5 + overlay_noise * 2)
			var end_y = min(start_y + Chunk.HEIGHT, max(noise, sea_level))
			for y in range(start_y, end_y):
				var block_index = Vector3i(x, y - start_y, z)
				assert(Chunk.in_bounds(block_index))
				if y > noise:
					blocks[block_index] = Block.Type.WATER
				elif (noise >= sea_level - 1 and noise < sea_level + overlay_noise * 2) \
					or (y > noise - 2 and noise <= sea_level):
					blocks[block_index] = Block.Type.SAND
				elif y > 20 + overlay_noise * 2:
					blocks[block_index] = Block.Type.STONE
				elif y == noise - 1:
					blocks[block_index] = Block.Type.GRASS
					var foliage_noise = _foliage_generator.get_noise_2d(block_x, block_z)
					var foliage_value = int(foliage_noise * 13793) % 100
					if foliage_value < 2 and _tree_in_bounds(x, z):
						_tree(blocks, x, noise - start_y, z)
					else:
						_foliage(blocks, block_index + Vector3i.UP, foliage_value)
				elif y > noise - 4:
					blocks[block_index] = Block.Type.DIRT
				else:
					blocks[block_index] = Block.Type.STONE

func _tree(blocks: Dictionary[Vector3i, Block.Type], x: int, y: int, z: int) -> void:
	var height = int((_tree_generator.get_noise_2d(x, z) + 1.0) * 2.0) + 4
	for i in range(height):
		var index = Vector3i(x, y + i, z)
		if Chunk.in_bounds(index):
			blocks[index] = Block.Type.LOG
	for lx in range(-2, 3):
		for ly in range(-2, 3):
			for lz in range(-2, 3):
				if abs(lx) + abs(ly) + abs(lz) > 3:
					continue
				var index = Vector3i(x + lx, y + height - 2 + ly, z + lz)
				if Chunk.in_bounds(index) and index not in blocks:
					blocks[index] = Block.Type.LEAVES

func _foliage(blocks: Dictionary[Vector3i, Block.Type], index: Vector3i, value: int) -> void:
	if value > 10 and value < 50:
		blocks[index] = Block.Type.BUSH
	elif value > 50 and value < 53:
		blocks[index] = Block.Type.POPPY
	elif value > 56 and value < 59:
		blocks[index] = Block.Type.DANDELION
	elif value > 62 and value < 65:
		blocks[index] = Block.Type.DAISY
	elif value > 68 and value < 71:
		blocks[index] = Block.Type.CORNFLOWER
	elif value > 74 and value < 77:
		blocks[index] = Block.Type.MARIGOLD
	elif value > 80 and value < 83:
		blocks[index] = Block.Type.LAVENDER

func _tree_in_bounds(x: int, z: int) -> bool:
	return x > 1 and z > 1 and x < Chunk.SIZE.x - 2 and z < Chunk.SIZE.z - 2

func _debug(_index: Vector3i, _blocks: Dictionary[Vector3i, Block.Type]) -> void:
	_blocks[Vector3i(0, 0, 0)] = Block.Type.GRASS

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

func generate(index: Vector3i) -> Dictionary[Vector3i, Block.Type]:
	var blocks: Dictionary[Vector3i, Block.Type] = {}
	match type:
		Type.NOISE:
			_noise(index, blocks)
		Type.SUPERFLAT:
			_superflat(index, blocks)
		Type.DEBUG:
			_debug(index, blocks)
	assert(not blocks.is_empty())
	return blocks
