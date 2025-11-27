class_name Chunk extends StaticBody3D

const HIGH_PRIORITY = false

const WIDTH = 32
const HEIGHT = 256
const SIZE = Vector3i(WIDTH, HEIGHT, WIDTH)

enum Flag {
	NONE = 0,
	GENERATING = 0b00000001,
	GENERATED  = 0b00000010,
	EXPOSED    = 0b00000100,
	MESHING    = 0b00001000,
	MESHED     = 0b00010000,
	WORKING = GENERATING | MESHING,
}

enum MeshType {
	OPAQUE,
	TRANSPARENT,
	COUNT,
}

var _world = null
var _index: Vector3i
var _flags = Flag.NONE
var _all_blocks: Dictionary[Vector3i, Block.Type] = {}
var _exposed_blocks: Dictionary[Vector3i, Block.Type] = {}

func _init(world, index: Vector3i) -> void:
	_world = world
	_index = index

func set_flag(flag: Flag) -> void:
	assert(not has_flag(flag))
	_flags = (_flags | flag) as Flag
	
func clear_flag(flag: Flag) -> void:
	assert(has_flag(flag))
	_flags = (_flags & ~flag) as Flag
	
func has_flag(flag: Flag) -> bool:
	return _flags & flag

func _start_task(method: StringName, async: bool) -> void:
	var callable = Callable(self, method)
	if not async:
		callable.call()
		return
	var task_id = WorkerThreadPool.add_task(callable, HIGH_PRIORITY)
	_world.task_ids[task_id] = true

static func in_bounds(index: Vector3i) -> bool:
	return \
		index.x >= 0 and index.x < SIZE.x and \
		index.y >= 0 and index.y < SIZE.y and \
		index.z >= 0 and index.z < SIZE.z

func get_block(index: Vector3i) -> Block.Type:
	return _all_blocks.get(index, Block.Type.EMPTY)

func _get_local_position(index: Vector3i) -> Vector3i:
	return (index % SIZE + SIZE) % SIZE

func _get_block(index: Vector3i, normal: Vector3i) -> Block.Type:
	index += normal
	if in_bounds(index):
		return get_block(index)
	assert(normal.y == 0)
	var neighbor_chunk_index = _index + normal
	var neighbor_chunk = _world.get_chunk(neighbor_chunk_index)
	assert(neighbor_chunk.has_flag(Flag.GENERATED))
	var neighbor_index = _get_local_position(index)
	return neighbor_chunk.get_block(neighbor_index)

func _end_generate(task_id: int) -> void:
	clear_flag(Flag.GENERATING)
	set_flag(Flag.GENERATED)
	assert(not has_flag(Flag.MESHING))
	assert(not has_flag(Flag.MESHED))
	_world.task_ids.erase(task_id)

func _generate() -> void:
	_all_blocks = _world.generator.generate(_index)
	_end_generate.call_deferred(WorkerThreadPool.get_caller_task_id())

func _start_generate(async: bool) -> void:
	assert(!has_flag(Flag.GENERATED))
	assert(!has_flag(Flag.MESHED))
	assert(!has_flag(Flag.WORKING))
	_start_task(&"_generate", async)
	set_flag(Flag.GENERATING)

func _expose() -> void:
	assert(has_flag(Flag.GENERATED))
	assert(not has_flag(Flag.EXPOSED))
	assert(not has_flag(Flag.MESHED))
	assert(_exposed_blocks.is_empty())
	for index in _all_blocks:
		var block = _all_blocks.get(index)
		assert(block != Block.Type.EMPTY)
		for face in range(Block.Face.COUNT):
			if _should_skip_face(index, face):
				continue
			var normal = Block.get_normal(block, face)
			var neighbor_block = _get_block(index, normal)
			if Block.is_visible(block, neighbor_block):
				_exposed_blocks[index] = block
				break
	set_flag(Flag.EXPOSED)

func _add_face(arrays: Array, index: Vector3i, type: Block.Type, face: Block.Face) -> void:
	var start_index = arrays[Mesh.ARRAY_VERTEX].size()
	var location = Vector3(_index * SIZE + index)
	for i in range(4):
		arrays[Mesh.ARRAY_VERTEX].append(location + Block.get_vertex(type, face, i))
		arrays[Mesh.ARRAY_NORMAL].append(Block.get_normal(type, face))
		arrays[Mesh.ARRAY_TEX_UV].append(Block.get_texcoord(type, face))
		arrays[Mesh.ARRAY_TEX_UV2].append(Block.get_texcoord2(type, face, i))
	for i in Block.get_indices(type, face):
		arrays[Mesh.ARRAY_INDEX].append(start_index + i)

func _create_mesh_arrays() -> Array:
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array([])
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array([])
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array([])
	arrays[Mesh.ARRAY_TEX_UV2] = PackedVector2Array([])
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array([])
	return arrays

func _create_mesh_instance(arrays: Array, type: MeshType) -> MeshInstance3D:
	var array_mesh = ArrayMesh.new()
	if arrays[Mesh.ARRAY_VERTEX].is_empty():
		return null
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = array_mesh
	match type:
		MeshType.OPAQUE:
			mesh_instance.material_override = _world.resources.opaque_material
		MeshType.TRANSPARENT:
			mesh_instance.material_override = _world.resources.transparent_material
	return mesh_instance

func _create_collision_shape(arrays: Array) -> CollisionShape3D:
	var vertices = PackedVector3Array()
	for i in range(0, arrays[Mesh.ARRAY_VERTEX].size(), 4):
		for j in Block.get_indices(Block.Type.EMPTY, Block.Face.COUNT):
			vertices.append(arrays[Mesh.ARRAY_VERTEX][i + j])
	var concave_polygon_shape = ConcavePolygonShape3D.new()
	concave_polygon_shape.set_faces(vertices)
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = concave_polygon_shape
	return collision_shape
	
func _should_skip_face(index: Vector3i, face: Block.Face):
	return index.y == 0 and _index.y == 0 and face == Block.Face.DOWN

func _end_mesh(task_id: int) -> void:
	assert(not has_flag(Flag.GENERATING))
	assert(has_flag(Flag.GENERATED))
	clear_flag(Flag.MESHING)
	set_flag(Flag.MESHED)
	_world.task_ids.erase(task_id)

func _mesh() -> void:
	#for child in get_children():
		#remove_child(child)
		#child.queue_free()
	if not has_flag(Flag.EXPOSED):
		_expose()
	var _meshes = []
	for type in range(MeshType.COUNT):
		_meshes.append(_create_mesh_arrays())
	for index in _exposed_blocks:
		var block = _exposed_blocks.get(index)
		assert(block != Block.Type.EMPTY)
		for face in range(Block.Face.COUNT):
			if _should_skip_face(index, face):
				continue
			var normal = Block.get_normal(block, face)
			var neighbor_block = _get_block(index, normal)
			if not Block.is_visible(block, neighbor_block):
				continue
			if not Block.is_transparent(block):
				_add_face(_meshes[MeshType.OPAQUE], index, block, face)
			else:
				_add_face(_meshes[MeshType.TRANSPARENT], index, block, face)
	for type in range(MeshType.COUNT):
		var mesh_instance = _create_mesh_instance(_meshes[type], type)
		if mesh_instance:
			add_child.call_deferred(mesh_instance)
	var collision_shape = _create_collision_shape(_meshes[MeshType.OPAQUE])
	add_child.call_deferred(collision_shape)
	_end_mesh.call_deferred(WorkerThreadPool.get_caller_task_id())

func _start_mesh(async: bool) -> void:
	assert(has_flag(Flag.GENERATED))
	assert(!has_flag(Flag.MESHED))
	assert(!has_flag(Flag.WORKING))
	#if _world.is_ancestor_of(self):
		#_world.remove_child(self)
	_start_task(&"_mesh", async)
	set_flag(Flag.MESHING)

func generate_async() -> void:
	_start_generate(true)

func mesh() -> void:
	_start_mesh(false)

func mesh_async() -> void:
	_start_mesh(true)
