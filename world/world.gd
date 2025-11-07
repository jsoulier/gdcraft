extends Node3D

const _WIDTH = 8 # +1
const _HEIGHT = 8 # +1
const _SIZE = Vector3i(_WIDTH, _HEIGHT, _WIDTH)

@onready var _player = get_node("Player")
var _chunk_shader = preload("res://world/chunk.gdshader")
var _chunks: Dictionary[Vector3i, Chunk] = {}
var _player_chunk_index: Vector3i = Vector3i.MAX
var _generated: bool = false
var _meshed: bool = false
var generator: Generator = null
var chunk_material: ShaderMaterial = null

func _ready() -> void:
	chunk_material = ShaderMaterial.new()
	chunk_material.shader = _chunk_shader
	chunk_material.set_shader_parameter("spritesheet", Spritesheet.get_spritesheet())

func set_generator(type: Generator.Type) -> void:
	generator = Generator.new(type)

func get_chunk(index: Vector3i) -> Chunk:
	return _chunks.get(index, null)

func _process(_delta: float) -> void:
	var chunk_index = Vector3i(_player.position) / Chunk.SIZE
	if _player_chunk_index == chunk_index and _generated and _meshed:
		return
	_player_chunk_index = chunk_index
	# TODO: refactor
	@warning_ignore("integer_division")
	var size = _SIZE / 2
	var borderless_size = size - Vector3i(1, 1, 1)
	assert(borderless_size.x >= 0)
	assert(borderless_size.y >= 0)
	assert(borderless_size.z >= 0)
	_generated = true
	for x in range(-size.x, size.x + 1):
		for z in range(-size.z, size.z + 1):
			for y in range(-size.y, size.y + 1):
				var index = _player_chunk_index + Vector3i(x, y, z)
				var chunk = _chunks.get(index, null)
				if not chunk:
					chunk = Chunk.new(self, index)
					_chunks[index] = chunk
				if not chunk.has_flag(Chunk.Flag.GENERATED):
					assert(not chunk.has_flag(Chunk.Flag.MESHING))
					assert(not chunk.has_flag(Chunk.Flag.MESHED))
					_generated = false
					if not chunk.has_flag(Chunk.Flag.GENERATING):
						chunk.generate()
				chunk.clear_flag(Chunk.Flag.UNLOAD)
	if _generated:
		_meshed = true
		for x in range(-borderless_size.x, borderless_size.x + 1):
			for z in range(-borderless_size.z, borderless_size.z + 1):
				for y in range(-borderless_size.y, borderless_size.y + 1):
					var index = _player_chunk_index + Vector3i(x, y, z)
					var chunk = _chunks.get(index, null)
					assert(chunk)
					assert(not chunk.has_flag(Chunk.Flag.GENERATING))
					assert(chunk.has_flag(Chunk.Flag.GENERATED))
					if not chunk.has_flag(Chunk.Flag.MESHED):
						_meshed = false
						if not chunk.has_flag(Chunk.Flag.MESHING):
							chunk.mesh()
	for index in _chunks.keys():
		var chunk = _chunks[index]
		if not chunk.has_flag(Chunk.Flag.UNLOAD):
			chunk.set_flag(Chunk.Flag.UNLOAD)
			continue
		var free = true
		for i in range(Block.Face.COUNT):
			var block_normal = Block.get_normal(i as Block.Face)
			var neighbor_chunk_index = index + block_normal
			var neighbor_chunk = get_chunk(neighbor_chunk_index)
			if neighbor_chunk:
				if neighbor_chunk.has_flag(Chunk.Flag.MESHING):
					free = false
					break
		if free:
			chunk.queue_free()
			_chunks.erase(index)
