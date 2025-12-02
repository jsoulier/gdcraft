class_name World
extends Node

@export var load_radius = 10
@export var unload_radius = 12
@export var player_id = 0
@export var max_workers = 8
@onready var _player = $Player
@onready var _sky = $Sky
@onready var generator = $Generator
@onready var database = $Database
var _chunks: Dictionary[Vector3i, Chunk] = {}
var _generate_chunks: Array[Vector3i] = []
var _mesh_chunks: Array[Vector3i] = []
var _player_chunk_index = Vector3i.ZERO
var _task_ids: Dictionary[int, bool] = {}
	
func _ready() -> void:
	var mesh_radius = load_radius - 1
	for x in range(-load_radius, load_radius + 1):
		for y in range(-load_radius, load_radius + 1):
			_generate_chunks.append(Vector3i(x, 0, y))
	for x in range(-mesh_radius, mesh_radius + 1):
		for y in range(-mesh_radius, mesh_radius + 1):
			_mesh_chunks.append(Vector3i(x, 0, y))
	_mesh_chunks.sort_custom(_sort)
	database.load_player(_player, player_id)
	database.load_sky(_sky)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for task_id in _task_ids:
			WorkerThreadPool.wait_for_task_completion(task_id)
		database.save_player(_player, player_id)
		database.save_sky(_sky)

func _in_bounds(index: Vector3i) -> bool:
	assert(index.y == 0)
	assert(load_radius <= unload_radius)
	index -= _player_chunk_index
	return index.x >= -unload_radius and index.x <= unload_radius \
		and index.z >= -unload_radius and index.z <= unload_radius

func _sort(lhs: Vector3i, rhs: Vector3i) -> bool:
	assert(lhs.y == 0 and rhs.y == 0)
	return lhs.length() < rhs.length()

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

func _remesh(index: Vector3i) -> void:
	var chunk = get_chunk(index)
	if not chunk:
		return
	if chunk.has_flag(Chunk.Flag.WORKING) or not chunk.has_flag(Chunk.Flag.MESHED):
		return
	chunk.mesh(false, true)
	assert(not chunk.has_flag(Chunk.Flag.MESHED))

func _on_player_set_block(index: Vector3i, type: Block.Type) -> void:
	var chunk_index = Vector3i((Vector3(index) / Vector3(Chunk.SIZE)).floor())
	var block_index = index - chunk_index * Chunk.SIZE
	var chunk = get_chunk(chunk_index)
	if not chunk:
		return
	if chunk.has_flag(Chunk.Flag.WORKING) or not chunk.has_flag(Chunk.Flag.MESHED):
		return
	for face in range(Face.Type.COUNT):
		if face == Face.Type.UP or face == Face.Type.DOWN:
			continue
		var vector = Face.get_vector(face)
		var neighbor_chunk_index = chunk_index + vector
		var neighbor_chunk = get_chunk(neighbor_chunk_index)
		if not neighbor_chunk.has_flag(Chunk.Flag.GENERATED):
			return
	chunk.set_block(block_index, type)
	chunk.mesh(false)
	if block_index.x == 0:
		_remesh(chunk_index - Vector3i(1, 0, 0))
	elif block_index.x == Chunk.SIZE.x - 1:
		_remesh(chunk_index + Vector3i(1, 0, 0))
	if block_index.z == 0:
		_remesh(chunk_index - Vector3i(0, 0, 1))
	elif block_index.z == Chunk.SIZE.z - 1:
		_remesh(chunk_index + Vector3i(0, 0, 1))
	database.set_block(chunk_index, block_index, type)
