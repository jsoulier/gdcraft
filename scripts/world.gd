class_name World
extends Node

const LOAD_RADIUS = 10
const UNLOAD_RADIUS = 12

@onready var _player: Player = $Player
var generator = Generator.new()
var max_workers = OS.get_processor_count()
var _chunks: Dictionary[Vector3i, Chunk] = {}
var _generate_chunks: Array[Vector3i] = []
var _mesh_chunks: Array[Vector3i] = []
var _player_chunk_index = Vector3i.ZERO
var _task_ids: Dictionary[int, bool] = {}

func _init() -> void:
	for x in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
		for y in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
			_generate_chunks.append(Vector3i(x, 0, y))
	var mesh_radius = LOAD_RADIUS - 1
	for x in range(-mesh_radius, mesh_radius + 1):
		for y in range(-mesh_radius, mesh_radius + 1):
			_mesh_chunks.append(Vector3i(x, 0, y))
	_mesh_chunks.sort_custom(_sort)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for task_id in _task_ids:
			WorkerThreadPool.wait_for_task_completion(task_id)

func _in_bounds(index: Vector3i) -> bool:
	index -= _player_chunk_index
	return index.x >= -UNLOAD_RADIUS and index.x <= UNLOAD_RADIUS \
		and index.z >= -UNLOAD_RADIUS and index.z <= UNLOAD_RADIUS
	
func _ready() -> void:
	generator.type = Generator.Type.NOISE
	generator.generator_seed = 1337

func _sort(a: Vector3i, b: Vector3i) -> bool:
	assert(a.y == 0 and b.y == 0)
	return a.length() < b.length()

func add_task_id(task_id: int) -> void:
	assert(_task_ids.size() < max_workers)
	_task_ids[task_id] = false

func remove_task_id(task_id: int) -> void:
	assert(_task_ids.has(task_id))
	_task_ids.erase(task_id)

func get_chunk(index: Vector3i) -> Chunk:
	assert(index.y == 0)
	return _chunks.get(index, null)

func _generate() -> void:
	for index in _generate_chunks:
		if _task_ids.size() >= max_workers:
			return
		index += _player_chunk_index
		var chunk = _chunks.get(index, null)
		if not chunk:
			chunk = Chunk.new(self, index)
			add_child(chunk)
			_chunks[index] = chunk
		if chunk.has_flag(Chunk.Flag.GENERATING):
			continue
		elif not chunk.has_flag(Chunk.Flag.GENERATED):
			assert(not chunk.has_flag(Chunk.Flag.MESHING))
			assert(not chunk.has_flag(Chunk.Flag.MESHED))
			chunk.generate()

func _mesh():
	for index in _mesh_chunks:
		if _task_ids.size() >= max_workers:
			return
		index += _player_chunk_index
		var chunk = _chunks.get(index, null)
		assert(chunk)
		assert(not chunk.has_flag(Chunk.Flag.GENERATING))
		assert(chunk.has_flag(Chunk.Flag.GENERATED))
		if chunk.has_flag(Chunk.Flag.MESHING):
			continue
		elif not chunk.has_flag(Chunk.Flag.MESHED):
			chunk.mesh(true)

func _unload() -> void:
	for index in _chunks.keys():
		var chunk = _chunks[index]
		if chunk.has_flag(Chunk.Flag.WORKING):
			continue
		if _in_bounds(index):
			continue
		var free = true
		for face in range(Face.Type.COUNT):
			if face == Face.Type.UP or face == Face.Type.DOWN:
				continue
			var vector = Face.get_vector(face)
			var neighbor_chunk_index = index + vector
			var neighbor_chunk = get_chunk(neighbor_chunk_index)
			if not neighbor_chunk:
				continue
			if neighbor_chunk.has_flag(Chunk.Flag.MESHING):
				free = false
				break
		if not free:
			continue
		_chunks.erase(index)
		remove_child(chunk)
		WorkerThreadPool.add_task(func(): chunk.free())

func _process(_delta: float) -> void:
	_player_chunk_index = Vector3i(_player.position) / Chunk.WIDTH
	_player_chunk_index.y = 0
	var _workers = _task_ids.size()
	_generate()
	if _workers == _task_ids.size():
		_mesh()
	_unload()

func _on_player_set_block(index: Vector3i, type: Block.Type) -> void:
	pass
