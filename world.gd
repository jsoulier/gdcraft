extends Node3D

const _WIDTH = 8 # +1
const _HEIGHT = 2 # +1
const _SIZE = Vector3i(_WIDTH, _HEIGHT, _WIDTH)

@onready var _player = get_node("Player")
var _opaque_shader = preload("res://opaque.gdshader")
var _transparent_shader = preload("res://transparent.gdshader")
var _chunks: Dictionary[Vector3i, Chunk] = {}
var _player_chunk_index: Vector3i = Vector3i.MAX
var _generated: bool = false
var _meshed: bool = false
var generator: Generator = null
var opaque_material: ShaderMaterial = null
var transparent_material: ShaderMaterial = null
var _task_ids: Dictionary[int, bool] = {}

func _ready() -> void:
	var spritesheet = Spritesheet.get_spritesheet()
	opaque_material = ShaderMaterial.new()
	opaque_material.shader = _opaque_shader
	opaque_material.set_shader_parameter("spritesheet", spritesheet)
	opaque_material.render_priority = 1
	transparent_material = ShaderMaterial.new()
	transparent_material.shader = _transparent_shader
	transparent_material.set_shader_parameter("spritesheet", spritesheet)
	transparent_material.render_priority = 0

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		assert(_task_ids.is_empty())
	if what != NOTIFICATION_WM_CLOSE_REQUEST:
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
	for task_id in _task_ids:
		WorkerThreadPool.wait_for_task_completion(task_id)

func set_generator(type: Generator.Type) -> void:
	generator = Generator.new(type)

func get_chunk(index: Vector3i) -> Chunk:
	return _chunks.get(index, null)

func add_task_id(task_id: int) -> void:
	_task_ids[task_id] = false

func remove_task_id(task_id: int) -> void:
	_task_ids.erase(task_id)

func _process(_delta: float) -> void:
	var chunk_index = Vector3i(_player.position) / Chunk.SIZE
	chunk_index.y = 0
	if _player_chunk_index == chunk_index and _generated and _meshed:
		return
	_player_chunk_index = chunk_index
	@warning_ignore("integer_division")
	var size = _SIZE / 2
	var borderless_size = size - Vector3i(1, 1, 1)
	assert(borderless_size.x >= 0)
	assert(borderless_size.z >= 0)
	_generated = true
	for x in range(-size.x, size.x + 1):
		for z in range(-size.z, size.z + 1):
			for y in range(0, _HEIGHT):
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
				for y in range(0, _HEIGHT):
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
		if chunk.has_flag(Chunk.Flag.GENERATING) or chunk.has_flag(Chunk.Flag.MESHING):
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
