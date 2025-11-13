class_name Chunk extends StaticBody3D

enum Flag {
	NONE = 0,
	GENERATING = 1,
	MESHING = 2,
	GENERATED = 4,
	MESHED = 8,
	UNLOAD = 16,
	REMESH = 32,
	WORKING = GENERATING | MESHING
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

static func _in_bounds(index: Vector3i) -> bool:
	return \
		index.x >= 0 and \
		index.y >= 0 and \
		index.z >= 0 and \
		index.x < SIZE.x and \
		index.y < SIZE.y and \
		index.z < SIZE.z

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
	assert(_in_bounds(index))
	if type != Block.Type.EMPTY:
		_blocks[index] = type
	else:
		_blocks.erase(index)
	remesh()

func remesh() -> void:
	assert(not has_flag(Flag.WORKING))
	clear_flag(Flag.MESHED)
	set_flag(Flag.REMESH)

func generate() -> void:
	assert(not has_flag(Flag.GENERATING))
	assert(not has_flag(Flag.GENERATED))
	set_flag(Flag.GENERATING)
	_task_id = WorkerThreadPool.add_task(_generate, false)
	_world.add_task_id(_task_id)

func _generate() -> void:
	_blocks = _world.generator.generate(_index)
	clear_flag.call_deferred(Flag.GENERATING)
	set_flag.call_deferred(Flag.GENERATED)
	assert(not has_flag(Flag.MESHED))
	assert(not has_flag(Flag.MESHING))
	_world.remove_task_id.call_deferred(_task_id)
	_task_id = 0

func mesh() -> void:
	assert(not has_flag(Flag.GENERATING))
	assert(has_flag(Flag.GENERATED))
	assert(not has_flag(Flag.MESHING))
	assert(not has_flag(Flag.MESHED))
	set_flag(Flag.MESHING)
	if _world.is_ancestor_of(self):
		_world.remove_child(self)
	if has_flag(Flag.REMESH):
		_mesh()
		return
	_task_id = WorkerThreadPool.add_task(_mesh, false)
	_world.add_task_id(_task_id)

func _mesh() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var surface_tools = []
	for mesh_type in range(MeshType.COUNT):
		var surface_tool = SurfaceTool.new()
		surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		surface_tools.append(surface_tool)
	var chunk_position = Vector3(_index * SIZE)
	var all_chunk_vertices = [[], []]
	for index in _blocks:
		var block_type = get_block(index)
		if block_type == Block.Type.EMPTY:
			continue
		for i in range(Block.Face.COUNT):
			var block_position = Vector3(index)
			var block_face = i as Block.Face
			if block_position.y == 0 and chunk_position.y == 0:
				if block_face == Block.Face.DOWN:
					continue
			var block_normal = Block.get_normal(block_face)
			var neighbor_position = index + block_normal
			var neighbor_type = Block.Type.EMPTY
			if _in_bounds(neighbor_position):
				neighbor_type = get_block(neighbor_position)
			else:
				var neighbor_chunk_index = _index + block_normal
				var neighbor_chunk = _world.get_chunk(neighbor_chunk_index)
				if neighbor_chunk != null:
					assert(neighbor_chunk.has_flag(Flag.GENERATED))
					var local_position = _get_local_position(neighbor_position)
					neighbor_type = neighbor_chunk.get_block(local_position)
			if neighbor_type != Block.Type.EMPTY:
				if not Block.is_visible(block_type, neighbor_type):
					continue
			var block_vertices = Block.get_vertices(block_face)
			var block_face_index = Block.get_face_index(block_type, block_face)
			var block_texcoords = Block.get_texcoords(block_face)
			var block_indices = Block.get_indices()
			assert(block_vertices.size() == 4)
			assert(block_texcoords.size() == 4)
			assert(block_indices.size() == 6)
			var mesh_type = MeshType.OPAQUE
			if Block.is_transparent(block_type):
				mesh_type = MeshType.TRANSPARENT
			var surface_tool = surface_tools[mesh_type]
			var chunk_vertices = all_chunk_vertices[mesh_type]
			var first_index = chunk_vertices.size()
			surface_tool.set_normal(block_normal)
			for j in range(4):
				var vertex = chunk_position + block_position + block_vertices[j]
				surface_tool.set_uv(block_face_index)
				surface_tool.set_uv2(block_texcoords[j])
				surface_tool.add_vertex(vertex)
				chunk_vertices.append(vertex)
			for j in range(6):
				surface_tool.add_index(first_index + block_indices[j])
	for mesh_type in range(MeshType.COUNT):
		var surface_tool = surface_tools[mesh_type]
		var array_mesh = surface_tool.commit()
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = array_mesh
		mesh_instance.material_override = _world.opaque_material
		if mesh_type == MeshType.TRANSPARENT:
			mesh_instance.material_override = _world.transparent_material
		add_child.call_deferred(mesh_instance)
	# TODO: refactor
	var opaque_vertices = all_chunk_vertices[MeshType.OPAQUE]
	if opaque_vertices.size() > 0:
		var collision_shape = CollisionShape3D.new()
		var concave_shape = ConcavePolygonShape3D.new()
		var faces = PackedVector3Array()
		var indices = Block.get_indices()
		for i in range(0, opaque_vertices.size(), 4):
			for j in indices:
				faces.append(opaque_vertices[i + j])
		concave_shape.set_faces(faces)
		collision_shape.shape = concave_shape
		add_child.call_deferred(collision_shape)
	_world.add_child.call_deferred(self)
	clear_flag.call_deferred(Flag.MESHING)
	clear_flag.call_deferred(Flag.REMESH)
	set_flag.call_deferred(Flag.MESHED)
	if _task_id:
		_world.remove_task_id.call_deferred(_task_id)
		_task_id = 0
