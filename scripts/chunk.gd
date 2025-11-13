class_name Chunk extends StaticBody3D

enum Flag {
	NONE       = 0b0000000,
	GENERATING = 0b0000001,
	GENERATED  = 0b0000010,
	MESHING    = 0b0000100,
	MESHED     = 0b0001000,
	REMESH     = 0b0010000,
	UNLOAD     = 0b0100000,
	UNLOADING  = 0b1000000,
	WORKING = GENERATING | MESHING | UNLOADING
}

enum MeshType {
	OPAQUE,
	TRANSPARENT,
	COUNT,
}

const WIDTH = 10
const HEIGHT = 10
const SIZE = Vector3i(WIDTH, HEIGHT, WIDTH)

var _blocks: Dictionary[Vector3i, Block.Type] = {}
var _world = null
var _index: Vector3i
var _flags = Flag.NONE
var _task_id = 0

func _init(world, index: Vector3i) -> void:
	_world = world
	_index = index
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		assert(_task_id == 0)
	if what != NOTIFICATION_WM_CLOSE_REQUEST:
		return
	if _task_id >= 1:
		WorkerThreadPool.wait_for_task_completion(_task_id)

static func in_bounds(index: Vector3i) -> bool:
	return index >= Vector3i.ZERO and index < SIZE

func get_block(index: Vector3i) -> Block.Type:
	return _blocks.get(index, Block.Type.EMPTY)

func _get_local_position(index: Vector3i) -> Vector3i:
	return (index % SIZE + SIZE) % SIZE

func set_flag(flag: Flag) -> void:
	_flags = (_flags | flag) as Flag

func clear_flag(flag: Flag) -> void:
	_flags = (_flags & (~flag as int)) as Flag

func has_flag(flag: Flag) -> bool:
	return bool(_flags & flag)

func set_block(index: Vector3i, type: Block.Type) -> void:
	assert(in_bounds(index))
	_blocks[index] = type
	remesh()

func generate() -> void:
	assert(_task_id == 0)
	assert(not has_flag(Flag.WORKING))
	assert(not has_flag(Flag.GENERATED))
	set_flag(Flag.GENERATING)
	_task_id = WorkerThreadPool.add_task(_generate, false)
	_world.add_task_id(_task_id)

func _generate() -> void:
	assert(not has_flag(Flag.UNLOADING))
	assert(not has_flag(Flag.MESHED))
	_blocks = _world.generator.generate(_index)
	_remove_id.call_deferred()
	set_flag.call_deferred(Flag.GENERATED)
	clear_flag.call_deferred(Flag.GENERATING)
	assert(not has_flag(Flag.UNLOADING))

func mesh() -> void:
	assert(_task_id == 0)
	assert(not has_flag(Flag.WORKING))
	assert(has_flag(Flag.GENERATED))
	assert(not has_flag(Flag.MESHED))
	set_flag(Flag.MESHING)
	if _world.is_ancestor_of(self):
		_world.remove_child(self)
	if has_flag(Flag.REMESH):
		clear_flag(Flag.REMESH)
		_mesh()
		return
	_task_id = WorkerThreadPool.add_task(_mesh, false)
	_world.add_task_id(_task_id)

func _mesh() -> void:
	assert(not has_flag(Flag.UNLOADING))
	assert(not has_flag(Flag.MESHED))
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var chunk_position = Vector3(_index * SIZE)
	var chunk_vertices = [PackedVector3Array(), PackedVector3Array()]
	var chunk_uvs = [PackedVector2Array(), PackedVector2Array()]
	var chunk_uvs2 = [PackedVector2Array(), PackedVector2Array()]
	var chunk_normals = [PackedVector3Array(), PackedVector3Array()]
	var chunk_indices = [PackedInt32Array(), PackedInt32Array()]
	var block_indices = Block.get_indices()
	assert(block_indices.size() == 6)
	for index in _blocks:
		var block_type = _blocks[index]
		if block_type == Block.Type.EMPTY:
			continue
		var block_position = Vector3(index)
		for i in range(Block.Face.COUNT):
			var block_face = i as Block.Face
			if block_position.y == 0 and chunk_position.y == 0 and block_face == Block.Face.DOWN:
				continue
			var block_normal = Block.get_normal(block_face)
			var neighbor_position = index + block_normal
			var neighbor_type = Block.Type.EMPTY
			if in_bounds(neighbor_position):
				neighbor_type = get_block(neighbor_position)
			else:
				var neighbor_chunk_index = _index + block_normal
				var neighbor_chunk = _world.get_chunk(neighbor_chunk_index)
				if neighbor_chunk != null:
					assert(neighbor_chunk.has_flag(Flag.GENERATED))
					var local_position = _get_local_position(neighbor_position)
					neighbor_type = neighbor_chunk.get_block(local_position)
			if neighbor_type != Block.Type.EMPTY and not Block.is_visible(block_type, neighbor_type):
				continue
			var block_vertices = Block.get_vertices(block_face)
			var block_face_index = Block.get_face_index(block_type, block_face)
			var block_texcoords = Block.get_texcoords(block_face)
			assert(block_vertices.size() == 4)
			assert(block_texcoords.size() == 4)
			var mesh_type = MeshType.OPAQUE
			if Block.is_transparent(block_type):
				mesh_type = MeshType.TRANSPARENT
			var vertices = chunk_vertices[mesh_type]
			var normals = chunk_normals[mesh_type]
			var uvs = chunk_uvs[mesh_type]
			var uv2s = chunk_uvs2[mesh_type]
			var indices = chunk_indices[mesh_type]
			var first_index = vertices.size()
			for j in range(4):
				vertices.append(chunk_position + block_position + block_vertices[j])
				normals.append(block_normal)
				uvs.append(block_face_index)
				uv2s.append(block_texcoords[j])
			for j in block_indices:
				indices.append(first_index + j)
	for mesh_type in range(MeshType.COUNT):
		var vertices = chunk_vertices[mesh_type]
		if vertices.is_empty():
			continue
		var arrays = []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(vertices)
		arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(chunk_normals[mesh_type])
		arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array(chunk_uvs[mesh_type])
		arrays[Mesh.ARRAY_TEX_UV2] = PackedVector2Array(chunk_uvs2[mesh_type])
		arrays[Mesh.ARRAY_INDEX] = chunk_indices[mesh_type]
		var array_mesh = ArrayMesh.new()
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = array_mesh
		mesh_instance.material_override = _world.opaque_material
		if mesh_type == MeshType.TRANSPARENT:
			mesh_instance.material_override = _world.transparent_material
		add_child.call_deferred(mesh_instance)
	var opaque_vertices = chunk_vertices[MeshType.OPAQUE]
	if opaque_vertices.size() > 0:
		var collision_shape = CollisionShape3D.new()
		var concave_shape = ConcavePolygonShape3D.new()
		var faces = PackedVector3Array()
		for i in range(0, opaque_vertices.size(), 4):
			for j in block_indices:
				faces.append(opaque_vertices[i + j])
		concave_shape.set_faces(faces)
		collision_shape.shape = concave_shape
		add_child.call_deferred(collision_shape)
	_remove_id.call_deferred()
	set_flag.call_deferred(Flag.MESHED)
	clear_flag.call_deferred(Flag.MESHING)
	_world.add_child.call_deferred(self)
	assert(not has_flag(Flag.UNLOADING))

func _remove_id():
	if _task_id:
		_world.remove_task_id(_task_id)
		_task_id = 0

func remesh() -> void:
	assert(not has_flag(Flag.WORKING))
	clear_flag(Flag.MESHED)
	set_flag(Flag.REMESH)