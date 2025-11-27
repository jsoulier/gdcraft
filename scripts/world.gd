class_name World extends Node

@export var load_radius = 10
@export var unload_radius = 12
@export var max_workers = 12

@onready var _player: Player = $Player
@onready var _sun: DirectionalLight3D = $Sun
var resources = Resources.new()
var generator = Generator.new()
var _chunks: Dictionary[Vector3i, Chunk] = {}
var _sorted_chunks: Array[Vector3i] = []
var _borderless_sorted_chunks: Array[Vector3i] = []
var _player_chunk_index: Vector3i
var task_ids: Dictionary[int, bool] = {} # TODO: add add_task_id/remove and add asserts that we're less than max_workers

func _init() -> void:
	for x in range(-load_radius, load_radius + 1):
		for y in range(-load_radius, load_radius + 1):
			_sorted_chunks.append(Vector3i(x, 0, y))
	var borderless_radius = load_radius - 1
	for x in range(-borderless_radius, borderless_radius + 1):
		for y in range(-borderless_radius, borderless_radius + 1):
			_borderless_sorted_chunks.append(Vector3i(x, 0, y))
	var center = Vector3i(0, 0, 0)
	_sorted_chunks.sort_custom(
		func(a: Vector3i, b: Vector3i):
			assert(a.y == 0 and b.y == 0)
			return a.distance_to(center) < b.distance_to(center))
	_borderless_sorted_chunks.sort_custom(
		func(a: Vector3i, b: Vector3i):
			assert(a.y == 0 and b.y == 0)
			return a.distance_to(center) < b.distance_to(center))

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for task_id in task_ids:
			WorkerThreadPool.wait_for_task_completion(task_id)
	
func _ready() -> void:
	generator.type = Generator.Type.SUPERFLAT

func _preserve(index: Vector3i) -> bool:
	index -= _player_chunk_index
	return \
		index.x >= -unload_radius and index.x <= unload_radius and \
		index.z >= -unload_radius and index.z <= unload_radius

func _generate() -> int:
	var working = 0
	for index_2d in _sorted_chunks:
		if working >= max_workers:
			return working
		var index = _player_chunk_index + index_2d
		var chunk = _chunks.get(index, null)
		if not chunk:
			chunk = Chunk.new(self, index)
			# Chunk always needs to be added to ensure it's freed BEFORE the world (for threading reasons)
			add_child(chunk)
			_chunks[index] = chunk
		if chunk.has_flag(Chunk.Flag.GENERATING):
			working += 1
		elif not chunk.has_flag(Chunk.Flag.GENERATED):
			assert(not chunk.has_flag(Chunk.Flag.MESHING))
			assert(not chunk.has_flag(Chunk.Flag.MESHED))
			chunk.generate_async()
			working += 1
	return working

func _mesh(working: int) -> int:
	for index_2d in _borderless_sorted_chunks:
		if working >= max_workers:
			return working
		var index = _player_chunk_index + index_2d
		var chunk = _chunks.get(index, null)
		assert(chunk)
		assert(not chunk.has_flag(Chunk.Flag.GENERATING))
		assert(chunk.has_flag(Chunk.Flag.GENERATED))
		if chunk.has_flag(Chunk.Flag.MESHING):
			working += 1
			continue
		elif not chunk.has_flag(Chunk.Flag.MESHED):
			chunk.mesh_async()
			working += 1
	return working

func _unload() -> void:
	for index in _chunks.keys():
		var chunk = _chunks[index]
		if chunk.has_flag(Chunk.Flag.WORKING):
			continue
		if _preserve(index):
			continue
		var free = true
		for face in range(Block.Face.COUNT):
			if face == Block.Face.UP or face == Block.Face.DOWN:
				continue
			var block_normal = Block.get_normal(Block.Type.EMPTY, face)
			var neighbor_chunk_index = index + block_normal
			var neighbor_chunk = get_chunk(neighbor_chunk_index)
			if not neighbor_chunk:
				continue
			if neighbor_chunk.has_flag(Chunk.Flag.MESHING):
				free = false
				break
		if free:
			chunk.queue_free()
			_chunks.erase(index)

func _process(_delta: float) -> void:
	_player_chunk_index = Vector3i(_player.position) / Chunk.WIDTH
	_player_chunk_index.y = 0
	var workers = _generate()
	if not workers:
		_mesh(workers)
	_unload()

func get_chunk(index: Vector3i) -> Chunk:
	assert(index.y == 0)
	return _chunks.get(index, null)
